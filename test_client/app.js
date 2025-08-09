/**
 * Homie Backend Test Client JavaScript
 * WebSocket connection and event handling
 */

class HomieTestClient {
    constructor() {
        this.socket = null;
        this.connected = false;
        this.authenticated = false;
        this.sessionId = null;
        this.userId = null;
        this.currentModule = 'main_menu';
        this.connectionStartTime = null;
        
        // Statistics
        this.stats = {
            eventsReceived: 0,
            messagesSent: 0,
            connectionTime: '--'
        };
        
        this.initializeEventListeners();
        this.updateUI();
        this.startConnectionTimer();
    }
    
    initializeEventListeners() {
        // Update connection timer every second
        setInterval(() => {
            this.updateConnectionTime();
        }, 1000);
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
        
        this.updateStatus('disconnected', 'Disconnected');
        this.updateUI();
        this.log('info', 'Disconnected from server');
    }
    
    setupSocketEvents() {
        // Connection events
        this.socket.on('connect', () => {
            this.connected = true;
            this.connectionStartTime = new Date();
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
        const sessionInfoBtn = document.getElementById('session-info-btn');
        const customEventBtn = document.getElementById('custom-event-btn');
        const testAiBtn = document.getElementById('test-ai-btn');
        
        // Connection buttons
        connectBtn.disabled = this.connected;
        disconnectBtn.disabled = !this.connected;
        
        // Authentication button
        authBtn.disabled = !this.connected || this.authenticated;
        
        // Module and test buttons
        const authRequired = this.connected && this.authenticated;
        switchModuleBtn.disabled = !authRequired;
        sessionInfoBtn.disabled = !this.connected;
        customEventBtn.disabled = !this.connected;
        testAiBtn.disabled = !this.connected;
    }
    
    updateStats() {
        document.getElementById('events-count').textContent = this.stats.eventsReceived;
        document.getElementById('messages-count').textContent = this.stats.messagesSent;
        document.getElementById('current-module').textContent = this.currentModule || 'None';
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
        
        document.getElementById('connection-time').textContent = this.stats.connectionTime;
    }
    
    log(type, message, data = null) {
        const logContainer = document.getElementById('log-container');
        const timestamp = new Date().toLocaleTimeString();
        
        const logEntry = document.createElement('div');
        logEntry.className = `log-entry ${type}`;
        
        let content = `[${timestamp}] ${message}`;
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

// Global functions for HTML onclick handlers
let client;

function connect() {
    client.connect();
}

function disconnect() {
    client.disconnect();
}

function authenticate() {
    client.authenticate();
}

function switchModule() {
    client.switchModule();
}

function getSessionInfo() {
    client.getSessionInfo();
}

function sendCustomEvent() {
    client.sendCustomEvent();
}

function testAI() {
    client.testAI();
}

function testConnection() {
    client.testConnection();
}

function clearLogs() {
    client.clearLogs();
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
    client = new HomieTestClient();
});