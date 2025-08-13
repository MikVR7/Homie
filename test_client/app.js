/**
 * Homie Backend Multi-User Test Client JavaScript
 * WebSocket connection and event handling for multiple concurrent users
 */

class HomieTestClient {
    constructor(userId, displayName) {
        this.userId = userId;
        this.displayName = displayName;
        this.socket = null;
        this.connected = false;
        this.authenticated = false;
        this.sessionId = null;
        this.currentModule = 'main_menu';
        this.connectionStartTime = null;
        
        // Statistics
        this.stats = {
            eventsReceived: 0,
            messagesSent: 0,
            connectionTime: '--'
        };
        
        this.initializeEventListeners();
    }
    
    initializeEventListeners() {
        // Each user has their own timer - will be started/stopped as needed
        this.connectionTimer = null;
        this.driveMonitoringTimer = null;
    }
    
    startConnectionTimer() {
        if (this.connectionTimer) {
            clearInterval(this.connectionTimer);
        }
        this.connectionTimer = setInterval(() => {
            this.updateConnectionTime();
            // ONLY update UI if this is the currently displayed user
            try {
                if (typeof getCurrentUser === 'function' && this === getCurrentUser()) {
                    this.updateStats();
                }
            } catch (e) {
                // getCurrentUser might not be available during initialization
            }
        }, 1000);
    }
    
    stopConnectionTimer() {
        if (this.connectionTimer) {
            clearInterval(this.connectionTimer);
            this.connectionTimer = null;
        }
        this.stats.connectionTime = '--';
        this.updateStats(); // Force immediate UI update
    }
    
    connect() {
        const serverUrl = document.getElementById('server-url').value;
        
        if (this.socket) {
            this.disconnect();
        }
        
        this.log('info', `Connecting to ${serverUrl}...`);
        this.updateStatus('connecting', 'Connecting...');
        
        try {
            this.socket = io(serverUrl, {
                transports: ['websocket'],
                timeout: 5000
            });
            
            this.setupSocketEvents();
            
        } catch (error) {
            this.log('error', `Connection failed: ${error.message}`);
            this.updateStatus('disconnected', 'Connection Failed');
        }
    }
    
    disconnect() {
        if (this.socket) {
            this.socket.disconnect();
            this.socket = null;
        }
        
        this.connected = false;
        this.authenticated = false;
        this.sessionId = null;
        this.connectionStartTime = null;
        this.currentModule = 'main_menu';
        this.stopConnectionTimer();
        this.stopDriveMonitoring();
        
        this.updateStatus('disconnected', 'Disconnected');
        this.updateUI();
        this.log('info', 'Disconnected from server');
    }
    
    setupSocketEvents() {
        // Connection events
        this.socket.on('connect', () => {
            this.connected = true;
            this.connectionStartTime = new Date();
            this.startConnectionTimer();
            this.updateStatus('connected', 'Connected');
            this.updateUI();
            this.log('info', '✅ Connected to server');
            this.stats.eventsReceived++;
            this.updateStats();
        });
        
        this.socket.on('disconnect', (reason) => {
            this.connected = false;
            this.authenticated = false;
            this.connectionStartTime = null;
            this.stopConnectionTimer();
            this.updateStatus('disconnected', `Disconnected: ${reason}`);
            this.updateUI();
            this.log('error', `❌ Disconnected: ${reason}`);
        });
        
        this.socket.on('connect_error', (error) => {
            this.updateStatus('disconnected', 'Connection Error');
            this.log('error', `❌ Connection error: ${error.message}`);
        });
        
        // Custom backend events
        this.setupBackendEventListeners();
    }
    
    setupBackendEventListeners() {
        // Authentication response
        this.socket.on('auth_response', (data) => {
            this.log('event', 'Authentication Response', data);
            if (data.success) {
                this.authenticated = true;
                this.sessionId = data.session_id;
                this.userId = data.user_id;
                this.updateUI();
            }
            this.stats.eventsReceived++;
            this.updateStats();
        });
        
        // Module switch response
        this.socket.on('module_switch_response', (data) => {
            this.log('event', 'Module Switch Response', data);
            if (data.success) {
                this.currentModule = data.new_module;
                this.updateStats();
            }
            this.stats.eventsReceived++;
            this.updateStats();
        });
        
        // Specific responses
        this.socket.on('file_organizer_drive_status', (data) => {
            this.log('event', 'Drive Status', data);
            this.stats.eventsReceived++;
            this.updateStats();
        });

        this.socket.on('folder_history_response', (data) => {
            this.log('event', 'Folder History', data);
            this.stats.eventsReceived++;
            this.updateStats();
        });

        this.socket.on('folder_summary_response', (data) => {
            this.log('event', 'Folder Summary', data);
            this.stats.eventsReceived++;
            this.updateStats();
        });

        // Backend events
        const backendEvents = [
            'client_connected',
            'client_disconnected', 
            'user_authenticated',
            'module_switched',
            'file_organizer_user_joining',
            'file_organizer_user_leaving',
            'financial_manager_user_joining',
            'financial_manager_user_leaving',
            'drive_connected',
            'drive_disconnected',
            'drive_discovered',
            'ai_response',
            'error'
        ];
        
        backendEvents.forEach(eventType => {
            this.socket.on(eventType, (data) => {
                this.log('event', `Backend Event: ${eventType}`, data);
                this.stats.eventsReceived++;
                this.updateStats();
            });
        });
        
        // Catch-all for any other events
        this.socket.onAny((eventName, data) => {
            if (!backendEvents.includes(eventName) && 
                !['connect', 'disconnect', 'connect_error', 'auth_response', 'module_switch_response'].includes(eventName)) {
                this.log('event', `Unknown Event: ${eventName}`, data);
                this.stats.eventsReceived++;
                this.updateStats();
            }
        });
    }
    
    authenticate() {
        if (!this.connected || !this.socket) {
            this.log('error', 'Not connected to server');
            return;
        }
        
        const userId = document.getElementById('user-id').value.trim();
        if (!userId) {
            this.log('error', 'Please enter a User ID');
            return;
        }
        
        const credentials = {
            user_id: userId,
            timestamp: new Date().toISOString(),
            client_type: 'test_client'
        };
        
        this.log('info', `Authenticating as: ${userId}`);
        this.socket.emit('authenticate', credentials);
        this.stats.messagesSent++;
        this.updateStats();
    }
    
    switchModule() {
        if (!this.authenticated || !this.socket) {
            this.log('error', 'Not authenticated');
            return;
        }
        
        const newModule = document.getElementById('module-select').value;
        
        this.log('info', `Switching to module: ${newModule}`);
        this.socket.emit('switch_module', { module: newModule });
        this.stats.messagesSent++;
        this.updateStats();
    }
    
    getSessionInfo() {
        if (!this.connected || !this.socket) {
            this.log('error', 'Not connected');
            return;
        }
        
        this.log('info', 'Requesting session info');
        this.socket.emit('get_session_info');
        this.stats.messagesSent++;
        this.updateStats();
    }
    
    sendCustomEvent() {
        if (!this.connected || !this.socket) {
            this.log('error', 'Not connected');
            return;
        }
        
        const eventData = {
            message: 'Hello from test client!',
            timestamp: new Date().toISOString(),
            test_data: {
                number: Math.random(),
                array: [1, 2, 3],
                nested: { key: 'value' }
            }
        };
        
        this.log('info', 'Sending custom test event');
        this.socket.emit('test_event', eventData);
        this.stats.messagesSent++;
        this.updateStats();
    }
    
    testAI() {
        if (!this.connected || !this.socket) {
            this.log('error', 'Not connected');
            return;
        }
        
        this.log('info', 'Testing AI connection');
        this.socket.emit('test_ai_connection');
        this.stats.messagesSent++;
        this.updateStats();
    }

    requestDriveStatus() {
        if (!this.connected || !this.socket) {
            this.log('error', 'Not connected');
            return;
        }
        this.log('info', 'Requesting drive status');
        this.socket.emit('request_drive_status', {});
        this.stats.messagesSent++;
        this.updateStats();
    }

    requestFolderHistory() {
        if (!this.connected || !this.socket) {
            this.log('error', 'Not connected');
            return;
        }
        const folderPath = document.getElementById('folder-path').value.trim();
        const limit = parseInt(document.getElementById('history-limit').value || '50', 10);
        if (!folderPath) {
            this.log('error', 'Please enter a folder path');
            return;
        }
        this.log('info', `Requesting folder history: ${folderPath}`);
        this.socket.emit('request_folder_history', { folder_path: folderPath, limit });
        this.stats.messagesSent++;
        this.updateStats();
    }

    requestFolderSummary() {
        if (!this.connected || !this.socket) {
            this.log('error', 'Not connected');
            return;
        }
        const folderPath = document.getElementById('folder-path').value.trim();
        if (!folderPath) {
            this.log('error', 'Please enter a folder path');
            return;
        }
        this.log('info', `Requesting folder summary: ${folderPath}`);
        this.socket.emit('request_folder_summary', { folder_path: folderPath });
        this.stats.messagesSent++;
        this.updateStats();
    }
    
    testConnection() {
        const serverUrl = document.getElementById('server-url').value;
        
        this.log('info', `Testing HTTP connection to ${serverUrl}...`);
        
        fetch(`${serverUrl}/api/health`)
            .then(response => response.json())
            .then(data => {
                this.log('info', 'HTTP Health Check', data);
            })
            .catch(error => {
                this.log('error', `HTTP test failed: ${error.message}`);
            });
    }
    
    updateStatus(status, text) {
        const indicator = document.getElementById('status-indicator');
        const statusText = document.getElementById('status-text');
        
        indicator.className = `status-indicator status-${status}`;
        statusText.textContent = text;
    }
    
    updateUI() {
        const connectBtn = document.getElementById('connect-btn');
        const disconnectBtn = document.getElementById('disconnect-btn');
        const authBtn = document.getElementById('auth-btn');
        const switchModuleBtn = document.getElementById('switch-module-btn');
        const testAiBtn = document.getElementById('test-ai-btn');
        const historyBtn = document.getElementById('history-btn');
        const summaryBtn = document.getElementById('summary-btn');
        
        // Connection buttons (with null checks)
        if (connectBtn) connectBtn.disabled = this.connected;
        if (disconnectBtn) disconnectBtn.disabled = !this.connected;
        
        // Authentication button
        if (authBtn) authBtn.disabled = !this.connected || this.authenticated;
        
        // Module and test buttons
        const authRequired = this.connected && this.authenticated;
        if (switchModuleBtn) switchModuleBtn.disabled = !authRequired;
        if (testAiBtn) testAiBtn.disabled = !this.connected;
        if (historyBtn) historyBtn.disabled = !authRequired;
        if (summaryBtn) summaryBtn.disabled = !authRequired;
        
        // Show/hide module selection panel based on auth status
        const modulePanel = document.getElementById('module-selection-panel');
        if (modulePanel) {
            modulePanel.style.display = authRequired ? 'block' : 'none';
        }
        
        // Update module-specific controls
        this.updateModuleControls();
    }
    
    updateModuleControls() {
        const selectedModule = document.getElementById('module-select').value;
        const controlsContainer = document.getElementById('module-specific-controls');
        
        // Clear existing controls
        controlsContainer.innerHTML = '';
        
        // Show/hide the module controls area
        if (selectedModule && selectedModule !== 'main_menu') {
            controlsContainer.style.display = 'block';
        } else {
            controlsContainer.style.display = 'none';
            return;
        }
        
        if (selectedModule === 'main_menu') {
            return; // No specific controls for main menu
        }
        
        const moduleDiv = document.createElement('div');
        moduleDiv.className = 'module-controls';
        
        if (selectedModule === 'file_organizer') {
            moduleDiv.innerHTML = `
                <h2 style="text-align: center; color: #e9ecef; margin-bottom: 30px;">🗂️ File Organizer Testing</h2>
                
                <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 25px; margin-bottom: 30px;">
                    <!-- Main Controls -->
                    <div>
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 25px;">
                            <div style="padding: 20px; background: #3a3a3a; border-radius: 8px; border: 1px solid #555;">
                                <h4 style="margin-top: 0; color: #e9ecef;">📂 Source Folder</h4>
                                <input type="text" id="fo-source-path" value="/home/mikele/Downloads" 
                                       style="width: 100%; padding: 12px; border: 1px solid #555; border-radius: 6px; font-size: 14px; background: #2a2a2a; color: #e9ecef;">
                                <small style="color: #adb5bd; display: block; margin-top: 8px;">Folder to analyze and organize</small>
                            </div>
                            <div style="padding: 20px; background: #3a3a3a; border-radius: 8px; border: 1px solid #555;">
                                <h4 style="margin-top: 0; color: #e9ecef;">🎯 Intent (Optional)</h4>
                                <input type="text" id="fo-intent" placeholder="e.g., 'organize movies'"
                                       style="width: 100%; padding: 12px; border: 1px solid #555; border-radius: 6px; font-size: 14px; background: #2a2a2a; color: #e9ecef;">
                                <small style="color: #adb5bd; display: block; margin-top: 8px;">What you want to achieve</small>
                            </div>
                        </div>
                        
                        <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px;">
                            <button onclick="testFileOrganizerAnalyze()" id="fo-analyze-btn" 
                                    style="padding: 15px; background: #0d6efd; color: white; border: none; border-radius: 6px; font-size: 16px; cursor: pointer; transition: background 0.2s;">
                                🔍 Analyze Folder
                            </button>
                            <button onclick="testFileOrganizerExecute()" id="fo-execute-btn"
                                    style="padding: 15px; background: #198754; color: white; border: none; border-radius: 6px; font-size: 16px; cursor: pointer; transition: background 0.2s;">
                                ⚡ Execute Operations
                            </button>
                            <button onclick="refreshDrives()" id="fo-refresh-drives-btn"
                                    style="padding: 15px; background: #6c757d; color: white; border: none; border-radius: 6px; font-size: 16px; cursor: pointer; transition: background 0.2s;">
                                🔄 Refresh Drives
                            </button>
                        </div>
                    </div>
                    
                    <!-- Live Drives Panel -->
                    <div style="padding: 20px; background: #3a3a3a; border-radius: 8px; border: 1px solid #555;">
                        <h4 style="margin-top: 0; color: #e9ecef; display: flex; align-items: center; gap: 10px;">
                            💾 Live Drives 
                            <span id="drives-status" style="font-size: 12px; color: #28a745;">●</span>
                        </h4>
                        <div id="drives-list" style="max-height: 200px; overflow-y: auto;">
                            <div style="color: #adb5bd; text-align: center; padding: 20px; font-style: italic;">
                                Loading drives...
                            </div>
                        </div>
                        <small style="color: #adb5bd; display: block; margin-top: 10px;">
                            USB drives will appear/disappear automatically
                        </small>
                    </div>
                </div>
                
                <div id="fo-result" style="padding: 20px; background: #3a3a3a; border-radius: 8px; min-height: 100px; max-height: 400px; overflow-y: auto; border: 1px solid #555;">
                    <p style="color: #adb5bd; margin: 0; text-align: center; font-style: italic;">Test results will appear here...</p>
                </div>
            `;
        } else if (selectedModule === 'financial_manager') {
            moduleDiv.innerHTML = `
                <h2 style="text-align: center; color: #e9ecef; margin-bottom: 30px;">💰 Financial Manager Testing</h2>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 25px; margin-bottom: 30px;">
                    <div style="padding: 20px; background: #3a3a3a; border-radius: 8px; border: 1px solid #555;">
                        <h4 style="margin-top: 0; color: #e9ecef;">🏦 Account Name</h4>
                        <input type="text" id="fm-account-name" value="Test Account" placeholder="Account name"
                               style="width: 100%; padding: 12px; border: 1px solid #555; border-radius: 6px; font-size: 14px; background: #2a2a2a; color: #e9ecef;">
                        <small style="color: #adb5bd; display: block; margin-top: 8px;">Name of the account to work with</small>
                    </div>
                    <div style="padding: 20px; background: #3a3a3a; border-radius: 8px; border: 1px solid #555;">
                        <h4 style="margin-top: 0; color: #e9ecef;">💵 Amount</h4>
                        <input type="number" id="fm-amount" value="1000" placeholder="Amount"
                               style="width: 100%; padding: 12px; border: 1px solid #555; border-radius: 6px; font-size: 14px; background: #2a2a2a; color: #e9ecef;">
                        <small style="color: #adb5bd; display: block; margin-top: 8px;">Transaction amount</small>
                    </div>
                </div>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px; margin-bottom: 25px;">
                    <button onclick="testFinancialSummary()" id="fm-summary-btn"
                            style="padding: 15px; background: #0d6efd; color: white; border: none; border-radius: 6px; font-size: 16px; cursor: pointer; transition: background 0.2s;">
                        📊 Get Summary
                    </button>
                    <button onclick="testFinancialAccounts()" id="fm-accounts-btn"
                            style="padding: 15px; background: #198754; color: white; border: none; border-radius: 6px; font-size: 16px; cursor: pointer; transition: background 0.2s;">
                        🏦 Manage Accounts
                    </button>
                    <button onclick="testFinancialTransaction()" id="fm-transaction-btn"
                            style="padding: 15px; background: #dc3545; color: white; border: none; border-radius: 6px; font-size: 16px; cursor: pointer; transition: background 0.2s;">
                        💸 Add Transaction
                    </button>
                </div>
                
                <div id="fm-result" style="padding: 20px; background: #3a3a3a; border-radius: 8px; min-height: 100px; max-height: 400px; overflow-y: auto; border: 1px solid #555;">
                    <p style="color: #adb5bd; margin: 0; text-align: center; font-style: italic;">Test results will appear here...</p>
                </div>
            `;
        }
        
        controlsContainer.appendChild(moduleDiv);
        this.updateModuleButtonStates();
        
        // If File Organizer is selected, start drive monitoring
        if (selectedModule === 'file_organizer') {
            this.startDriveMonitoring();
        }
    }
    
    updateModuleButtonStates() {
        const isInCorrectModule = this.currentModule === document.getElementById('module-select').value;
        const canUseModule = this.connected && this.authenticated && isInCorrectModule;
        
        // File Organizer buttons
        const foAnalyzeBtn = document.getElementById('fo-analyze-btn');
        const foExecuteBtn = document.getElementById('fo-execute-btn');
        const foDrivesBtn = document.getElementById('fo-drives-btn');
        
        if (foAnalyzeBtn) foAnalyzeBtn.disabled = !canUseModule;
        if (foExecuteBtn) foExecuteBtn.disabled = !canUseModule;
        if (foDrivesBtn) foDrivesBtn.disabled = !canUseModule;
        
        // Financial Manager buttons
        const fmSummaryBtn = document.getElementById('fm-summary-btn');
        const fmAccountsBtn = document.getElementById('fm-accounts-btn');
        const fmTransactionBtn = document.getElementById('fm-transaction-btn');
        
        if (fmSummaryBtn) fmSummaryBtn.disabled = !canUseModule;
        if (fmAccountsBtn) fmAccountsBtn.disabled = !canUseModule;
        if (fmTransactionBtn) fmTransactionBtn.disabled = !canUseModule;
    }
    
    updateStats() {
        document.getElementById('events-count').textContent = this.stats.eventsReceived;
        document.getElementById('messages-count').textContent = this.stats.messagesSent;
        
        // Update current module display
        const moduleNameElement = document.getElementById('current-module-name');
        if (moduleNameElement) {
            moduleNameElement.textContent = this.currentModule || 'None';
        }
    }
    
    updateConnectionTime() {
        if (this.connectionStartTime) {
            const now = new Date();
            const diff = Math.floor((now - this.connectionStartTime) / 1000);
            const minutes = Math.floor(diff / 60);
            const seconds = diff % 60;
            this.stats.connectionTime = `${minutes}:${seconds.toString().padStart(2, '0')}`;
        } else {
            this.stats.connectionTime = '--';
        }
        
        // ONLY update the display if this is the currently selected user
        if (typeof getCurrentUser === 'function' && this === getCurrentUser()) {
            document.getElementById('connection-time').textContent = this.stats.connectionTime;
        }
    }
    
    startDriveMonitoring() {
        // Clear any existing timer
        if (this.driveMonitoringTimer) {
            clearInterval(this.driveMonitoringTimer);
        }
        
        // Initial drive fetch
        this.refreshDrives();
        
        // Set up automatic refresh every 3 seconds
        this.driveMonitoringTimer = setInterval(() => {
            if (typeof getCurrentUser === 'function' && this === getCurrentUser()) {
                this.refreshDrives();
            }
        }, 3000);
    }
    
    stopDriveMonitoring() {
        if (this.driveMonitoringTimer) {
            clearInterval(this.driveMonitoringTimer);
            this.driveMonitoringTimer = null;
        }
    }
    
    refreshDrives() {
        if (!this.connected) return;
        
        // Update status to show we're checking
        const statusElement = document.getElementById('drives-status');
        if (statusElement) {
            statusElement.style.color = '#ffc107';
            statusElement.textContent = '●';
        }
        
        // Call the backend
        fetch('http://localhost:8000/api/file_organizer/drives', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        })
        .then(response => response.json())
        .then(data => {
            this.updateDrivesDisplay(data);
            
            // Update status to show success
            if (statusElement) {
                statusElement.style.color = '#28a745';
                statusElement.textContent = '●';
            }
        })
        .catch(error => {
            console.error('Error fetching drives:', error);
            this.updateDrivesDisplay({ drives: [], error: 'Failed to fetch drives' });
            
            // Update status to show error
            if (statusElement) {
                statusElement.style.color = '#dc3545';
                statusElement.textContent = '●';
            }
        });
    }
    
    updateDrivesDisplay(data) {
        const drivesList = document.getElementById('drives-list');
        if (!drivesList) return;
        
        if (data.error) {
            drivesList.innerHTML = `
                <div style="color: #dc3545; text-align: center; padding: 20px;">
                    ❌ ${data.error}
                </div>
            `;
            return;
        }
        
        if (!data.drives || data.drives.length === 0) {
            drivesList.innerHTML = `
                <div style="color: #adb5bd; text-align: center; padding: 20px; font-style: italic;">
                    No drives detected
                </div>
            `;
            return;
        }
        
        // Group drives by type
        const local = data.drives.filter(d => d.type === 'local');
        const usb = data.drives.filter(d => d.type === 'usb');
        const network = data.drives.filter(d => d.type === 'network');
        
        let html = '';
        
        if (local.length > 0) {
            html += '<div style="margin-bottom: 15px;"><strong style="color: #e9ecef; font-size: 12px;">💻 LOCAL DRIVES</strong>';
            local.forEach(drive => {
                html += this.renderDriveItem(drive);
            });
            html += '</div>';
        }
        
        if (usb.length > 0) {
            html += '<div style="margin-bottom: 15px;"><strong style="color: #e9ecef; font-size: 12px;">🔌 USB DRIVES</strong>';
            usb.forEach(drive => {
                html += this.renderDriveItem(drive);
            });
            html += '</div>';
        }
        
        if (network.length > 0) {
            html += '<div style="margin-bottom: 15px;"><strong style="color: #e9ecef; font-size: 12px;">🌐 NETWORK DRIVES</strong>';
            network.forEach(drive => {
                html += this.renderDriveItem(drive);
            });
            html += '</div>';
        }
        
        drivesList.innerHTML = html;
    }
    
    renderDriveItem(drive) {
        const icon = drive.type === 'usb' ? '🔌' : drive.type === 'network' ? '🌐' : '💻';
        const sizeInfo = drive.size ? ` (${this.formatBytes(drive.size)})` : '';
        
        return `
            <div style="padding: 8px 12px; margin: 5px 0; background: #2a2a2a; border-radius: 4px; border: 1px solid #555; cursor: pointer;" 
                 onclick="selectDrivePath('${drive.path}')" title="Click to use as source path">
                <div style="color: #e9ecef; font-size: 14px; font-weight: bold;">
                    ${icon} ${drive.label || 'Unnamed Drive'}
                </div>
                <div style="color: #adb5bd; font-size: 12px;">
                    ${drive.path}${sizeInfo}
                </div>
            </div>
        `;
    }
    
    formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    }
    
    log(type, message, data = null) {
        const logContainer = document.getElementById('log-container');
        const timestamp = new Date().toLocaleTimeString();
        
        const logEntry = document.createElement('div');
        logEntry.className = `log-entry ${type}`;
        
        let content = `[${timestamp}] [${this.displayName}] ${message}`;
        if (data) {
            content += '\n' + JSON.stringify(data, null, 2);
        }
        
        logEntry.innerHTML = `
            <div class="log-timestamp">${timestamp}</div>
            <div class="log-content">${content}</div>
        `;
        
        logContainer.appendChild(logEntry);
        logContainer.scrollTop = logContainer.scrollHeight;
        
        // Keep only last 100 entries
        while (logContainer.children.length > 100) {
            logContainer.removeChild(logContainer.firstChild);
        }
    }
    
    clearLogs() {
        document.getElementById('log-container').innerHTML = '';
        this.log('info', 'Logs cleared');
    }
}

// Multi-User Management System
let users = [];
let currentUserIndex = 0;
let userIdCounter = 1;

// Initialize default users
function initializeUsers() {
    users = [
        new HomieTestClient('user_001', 'User 1'),
        new HomieTestClient('user_002', 'User 2'),
        new HomieTestClient('user_003', 'User 3')
    ];
    updateUserTabs();
    updateUIForCurrentUser();
}

function getCurrentUser() {
    return users[currentUserIndex];
}

function switchUser(index) {
    if (index >= 0 && index < users.length) {
        currentUserIndex = index;
        updateUserTabs();
        updateUIForCurrentUser();
        console.log(`Switched to ${users[index].displayName}`);
    }
}

function addUser() {
    userIdCounter++;
    const newUser = new HomieTestClient(`user_${userIdCounter.toString().padStart(3, '0')}`, `User ${userIdCounter}`);
    users.push(newUser);
    updateUserTabs();
    switchUser(users.length - 1);
}

function updateUserTabs() {
    const tabsContainer = document.querySelector('.user-tabs');
    const addBtn = tabsContainer.querySelector('.add-user-btn');
    
    // Clear existing tabs
    const existingTabs = tabsContainer.querySelectorAll('.user-tab');
    existingTabs.forEach(tab => tab.remove());
    
    // Add tabs for each user
    users.forEach((user, index) => {
        const tab = document.createElement('button');
        tab.className = `user-tab ${index === currentUserIndex ? 'active' : ''}`;
        tab.id = `user-tab-${index}`;
        tab.textContent = user.displayName;
        tab.onclick = () => switchUser(index);
        
        // Add connection indicator
        if (user.connected) {
            tab.textContent += ' 🟢';
        } else {
            tab.textContent += ' 🔴';
        }
        
        tabsContainer.insertBefore(tab, addBtn);
    });
}

function updateUIForCurrentUser() {
    const user = getCurrentUser();
    
    // Update current user display
    document.getElementById('current-user-name').textContent = user.displayName;
    
    // Update connection status
    const indicator = document.getElementById('status-indicator');
    const statusText = document.getElementById('status-text');
    
    if (user.connected) {
        indicator.className = 'status-indicator status-connected';
        statusText.textContent = user.authenticated ? 'Connected & Authenticated' : 'Connected';
    } else {
        indicator.className = 'status-indicator status-disconnected';
        statusText.textContent = 'Disconnected';
    }
    
    // IMMEDIATELY update stats and UI to show this user's current state
    user.updateStats();
    user.updateUI();
    
    // Force immediate connection time update for this user
    user.updateConnectionTime();
    
    // Update user ID input
    document.getElementById('user-id').value = user.userId;
    
    // Update tabs
    updateUserTabs();
}

// Multi-user operations
function connectAllUsers() {
    console.log('🔌 Connecting all users...');
    users.forEach(user => {
        if (!user.connected) {
            user.connect();
        }
    });
}

function disconnectAllUsers() {
    console.log('🔌 Disconnecting all users...');
    users.forEach(user => {
        if (user.connected) {
            user.disconnect();
        }
    });
}

function authenticateAllUsers() {
    console.log('🔐 Authenticating all users...');
    users.forEach(user => {
        if (user.connected && !user.authenticated) {
            user.authenticate();
        }
    });
}

function testConcurrentOperations() {
    console.log('⚡ Testing concurrent operations...');
    users.forEach((user, index) => {
        if (user.connected && user.authenticated) {
            setTimeout(() => {
                user.switchModule();
                setTimeout(() => {
                    user.requestDriveStatus();
                }, 500);
            }, index * 200);
        }
    });
}

function testUserIsolation() {
    console.log('👥 Testing user isolation...');
    users.forEach((user, index) => {
        if (user.connected && user.authenticated) {
            setTimeout(() => {
                user.socket.emit('request_folder_history', { 
                    folder_path: `/test/user${index + 1}`, 
                    limit: 10 
                });
            }, index * 100);
        }
    });
}

function broadcastTestEvent() {
    console.log('📡 Broadcasting test event from all users...');
    users.forEach((user, index) => {
        if (user.connected) {
            setTimeout(() => {
                user.sendCustomEvent();
            }, index * 50);
        }
    });
}

// Global functions for HTML onclick handlers (delegate to current user)
function connect() {
    getCurrentUser().connect();
}

function disconnect() {
    getCurrentUser().disconnect();
}

function authenticate() {
    getCurrentUser().authenticate();
}

function switchModule() {
    getCurrentUser().switchModule();
}

function getSessionInfo() {
    getCurrentUser().getSessionInfo();
}

function refreshDrives() {
    getCurrentUser().refreshDrives();
}

function selectDrivePath(drivePath) {
    const sourceInput = document.getElementById('fo-source-path');
    if (sourceInput) {
        sourceInput.value = drivePath;
        // Add visual feedback
        sourceInput.style.background = '#0d6efd';
        sourceInput.style.color = 'white';
        setTimeout(() => {
            sourceInput.style.background = '#2a2a2a';
            sourceInput.style.color = '#e9ecef';
        }, 500);
    }
}

function sendCustomEvent() {
    getCurrentUser().sendCustomEvent();
}

function testAI() {
    getCurrentUser().testAI();
}

function testConnection() {
    getCurrentUser().testConnection();
}

function clearLogs() {
    document.getElementById('log-container').innerHTML = '';
    getCurrentUser().log('info', 'Logs cleared');
}

// Module control functions
function onModuleChange() {
    updateUIForCurrentUser();
}

// File Organizer testing functions
function testFileOrganizerAnalyze() {
    const user = getCurrentUser();
    const sourcePath = document.getElementById('fo-source-path').value;
    const intent = document.getElementById('fo-intent').value;
    
    if (!sourcePath) {
        user.log('error', 'Please enter a source folder path');
        return;
    }
    
    user.log('info', `Analyzing folder: ${sourcePath}`);
    
    // Make HTTP request to organize endpoint
    fetch('http://localhost:8000/api/file-organizer/organize', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            folder_path: sourcePath,
            intent: intent || null
        })
    })
    .then(response => response.json())
    .then(data => {
        user.log('info', 'File Organizer Analysis Complete', data);
        displayFileOrganizerResult(data);
    })
    .catch(error => {
        user.log('error', `Analysis failed: ${error.message}`);
    });
}

function testFileOrganizerExecute() {
    const user = getCurrentUser();
    const resultDiv = document.getElementById('fo-result');
    
    if (resultDiv.classList.contains('hidden') || !window.lastFileOrganizerResult) {
        user.log('error', 'No operations to execute. Run analysis first.');
        return;
    }
    
    const operations = window.lastFileOrganizerResult.operations || [];
    if (operations.length === 0) {
        user.log('error', 'No operations found in analysis result');
        return;
    }
    
    user.log('info', `Executing ${operations.length} operations`);
    
    // Make HTTP request to execute operations
    fetch('http://localhost:8000/api/file-organizer/execute-operations', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            operations: operations,
            dry_run: false
        })
    })
    .then(response => response.json())
    .then(data => {
        user.log('info', 'Operations Executed', data);
        displayFileOrganizerResult(data, 'Execution Results');
    })
    .catch(error => {
        user.log('error', `Execution failed: ${error.message}`);
    });
}

function testFileOrganizerDrives() {
    const user = getCurrentUser();
    user.log('info', 'Getting drive status');
    user.requestDriveStatus();
}

function displayFileOrganizerResult(data, title = 'Analysis Results') {
    const resultDiv = document.getElementById('fo-result');
    window.lastFileOrganizerResult = data;
    
    let content = `<strong>${title}:</strong><br><br>`;
    
    if (data.success) {
        if (data.operations) {
            content += `<strong>Operations (${data.operations.length}):</strong><br>`;
            data.operations.forEach((op, index) => {
                content += `${index + 1}. ${op.type}: ${op.src || op.path || op.archive} → ${op.dest || 'N/A'}<br>`;
            });
        }
        
        if (data.analysis) {
            content += `<br><strong>Analysis:</strong><br>`;
            content += `- Total files: ${data.analysis.total_files}<br>`;
            content += `- Categories: ${Object.entries(data.analysis.categories).map(([cat, count]) => `${cat}(${count})`).join(', ')}<br>`;
            content += `- Duplicates: ${data.analysis.duplicates_found}<br>`;
            content += `- Archives: ${data.analysis.archives_found}<br>`;
        }
        
        if (data.results) {
            content += `<br><strong>Execution Results:</strong><br>`;
            const successful = data.results.filter(r => r.success).length;
            const failed = data.results.filter(r => !r.success).length;
            content += `- Successful: ${successful}<br>`;
            content += `- Failed: ${failed}<br>`;
        }
    } else {
        content += `<span style="color: #f44336;">Error: ${data.error}</span>`;
    }
    
    resultDiv.innerHTML = content;
    resultDiv.classList.remove('hidden');
}

// Financial Manager testing functions
function testFinancialSummary() {
    const user = getCurrentUser();
    user.log('info', 'Getting financial summary');
    // Placeholder for financial testing
}

function testFinancialAccounts() {
    const user = getCurrentUser();
    user.log('info', 'Testing account management');
    // Placeholder for financial testing
}

function testFinancialTransaction() {
    const user = getCurrentUser();
    user.log('info', 'Testing transaction creation');
    // Placeholder for financial testing
}

// Initialize when page loads AND Socket.IO is available
function initializeClient() {
    try {
        // Check for Socket.IO load error first
        if (window.socketIOLoadError) {
            console.error('❌ Cannot initialize client: Socket.IO failed to load');
            return;
        }
        
        // Check if Socket.IO is available
        if (typeof io === 'undefined' || !window.socketIOReady) {
            console.log('⏳ Socket.IO not ready yet, retrying...');
            setTimeout(initializeClient, 100);
            return;
        }
        
        initializeUsers();
        console.log('✅ Multi-User Test Client initialized successfully');
        
        // Set up automatic UI updates for switching between users
        setInterval(() => {
            // Only update tab indicators, don't interfere with individual timers
            updateUserTabs();
        }, 1000);
        
    } catch (e) {
        console.error('❌ Failed to initialize test client:', e);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    initializeClient();
});