// Homie Frontend - JavaScript Application
// Handles communication with the Python FastAPI backend

class HomieApp {
    constructor() {
        this.baseUrl = 'http://localhost:8000/api';
        this.currentScan = null;
        this.init();
    }

    init() {
        console.log('🏠 Homie Frontend initialized');
        this.setupEventListeners();
        this.updateStatus('Ready to scan...');
        
        // Set default scan path to user's home directory (for demo)
        const scanPathInput = document.getElementById('scan-path');
        if (scanPathInput && !scanPathInput.value) {
            scanPathInput.value = '/home/mikele/Downloads'; // Example default path
        }
    }

    setupEventListeners() {
        // Handle Enter key in scan path input
        const scanPathInput = document.getElementById('scan-path');
        if (scanPathInput) {
            scanPathInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.runDiscovery();
                }
            });
        }

        // Add escape key to cancel scan
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.currentScan) {
                this.cancelScan();
            }
        });
    }

    async runDiscovery() {
        const scanPath = document.getElementById('scan-path').value.trim();
        
        if (!scanPath) {
            this.updateStatus('❌ Please enter a valid path to scan', 'error');
            this.addLogEntry('Error: No scan path provided');
            return;
        }

        this.updateStatus('🔍 Starting folder discovery...', 'scanning');
        this.addLogEntry(`Starting scan of: ${scanPath}`);
        
        const discoverBtn = document.getElementById('discover-btn');
        if (discoverBtn) {
            discoverBtn.disabled = true;
            discoverBtn.textContent = '⏸️ Scanning...';
        }

        try {
            // Call the backend API
            const response = await this.callAPI('/discover', {
                method: 'POST',
                body: JSON.stringify({ path: scanPath }),
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (response.success) {
                this.handleDiscoveryResults(response.data);
                this.updateStatus('✅ Folder discovery completed successfully', 'success');
                this.addLogEntry(`Scan completed: Found ${response.data.total_folders || 0} folders, ${response.data.total_files || 0} files`);
            } else {
                throw new Error(response.error || 'Discovery failed');
            }

        } catch (error) {
            console.error('Discovery error:', error);
            this.updateStatus(`❌ Discovery failed: ${error.message}`, 'error');
            this.addLogEntry(`Error: ${error.message}`);
            this.showErrorDetails(error);
        } finally {
            // Re-enable the button
            if (discoverBtn) {
                discoverBtn.disabled = false;
                discoverBtn.textContent = '🔍 Discover Folders';
            }
            this.currentScan = null;
        }
    }

    async callAPI(endpoint, options = {}) {
        try {
            const url = `${this.baseUrl}${endpoint}`;
            console.log(`Making API call to: ${url}`);
            
            const response = await fetch(url, {
                ...options,
                headers: {
                    'Accept': 'application/json',
                    ...options.headers
                }
            });

            if (!response.ok) {
                if (response.status === 404) {
                    throw new Error('Backend server not running. Please start the Homie backend first.');
                }
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            return data;

        } catch (error) {
            if (error.name === 'TypeError' && error.message.includes('fetch')) {
                throw new Error('Cannot connect to backend server. Is it running on http://localhost:8000?');
            }
            throw error;
        }
    }

    handleDiscoveryResults(data) {
        console.log('Discovery results:', data);
        
        // Update summary
        this.updateResultsSummary(data);
        
        // Update folder tree
        this.updateFolderTree(data.folder_structure || {});
    }

    updateResultsSummary(data) {
        const summaryElement = document.getElementById('results-summary');
        if (!summaryElement) return;

        const summary = `
            <div class="summary-stats">
                <div class="stat-item">
                    <span class="stat-number">${data.total_folders || 0}</span>
                    <span class="stat-label">Folders Found</span>
                </div>
                <div class="stat-item">
                    <span class="stat-number">${data.total_files || 0}</span>
                    <span class="stat-label">Files Found</span>
                </div>
                <div class="stat-item">
                    <span class="stat-number">${data.scan_time || 'N/A'}</span>
                    <span class="stat-label">Scan Time</span>
                </div>
            </div>
            <div class="summary-insights">
                ${data.insights ? data.insights.map(insight => `<div class="insight">💡 ${insight}</div>`).join('') : ''}
            </div>
        `;
        
        summaryElement.innerHTML = summary;
    }

    updateFolderTree(folderStructure) {
        const treeElement = document.getElementById('folder-tree');
        if (!treeElement) return;

        if (Object.keys(folderStructure).length === 0) {
            treeElement.innerHTML = '<div class="no-results">No folder structure to display</div>';
            return;
        }

        const treeHTML = this.renderFolderTree(folderStructure);
        treeElement.innerHTML = `<div class="tree-container">${treeHTML}</div>`;
        
        // Add click handlers for expandable folders
        this.setupTreeInteractions();
    }

    renderFolderTree(structure, level = 0) {
        let html = '';
        
        for (const [folderName, folderData] of Object.entries(structure)) {
            const indent = '  '.repeat(level);
            const hasChildren = folderData.subfolders && Object.keys(folderData.subfolders).length > 0;
            const fileCount = folderData.file_count || 0;
            
            html += `
                <div class="tree-item" data-level="${level}">
                    <div class="tree-node ${hasChildren ? 'expandable' : ''}" style="margin-left: ${level * 20}px">
                        ${hasChildren ? '<span class="expand-icon">📁</span>' : '<span class="file-icon">📄</span>'}
                        <span class="folder-name">${folderName}</span>
                        <span class="file-count">(${fileCount} files)</span>
                    </div>
                    ${hasChildren ? `<div class="tree-children" style="display: none;">${this.renderFolderTree(folderData.subfolders, level + 1)}</div>` : ''}
                </div>
            `;
        }
        
        return html;
    }

    setupTreeInteractions() {
        // Add click handlers for expandable nodes
        document.querySelectorAll('.tree-node.expandable').forEach(node => {
            node.addEventListener('click', (e) => {
                e.stopPropagation();
                const children = node.parentElement.querySelector('.tree-children');
                const icon = node.querySelector('.expand-icon');
                
                if (children) {
                    if (children.style.display === 'none') {
                        children.style.display = 'block';
                        icon.textContent = '📂';
                    } else {
                        children.style.display = 'none';
                        icon.textContent = '📁';
                    }
                }
            });
        });
    }

    updateStatus(message, type = 'info') {
        const statusElement = document.getElementById('status');
        if (!statusElement) return;

        statusElement.textContent = message;
        statusElement.className = `status ${type}`;
        
        console.log(`Status: ${message}`);
    }

    addLogEntry(message) {
        const logContainer = document.getElementById('log-container');
        if (!logContainer) return;

        const timestamp = new Date().toLocaleTimeString();
        const logEntry = document.createElement('div');
        logEntry.className = 'log-entry';
        logEntry.innerHTML = `<span class="timestamp">[${timestamp}]</span> ${message}`;
        
        logContainer.appendChild(logEntry);
        
        // Keep only the last 50 log entries
        const entries = logContainer.querySelectorAll('.log-entry');
        if (entries.length > 50) {
            entries[0].remove();
        }
        
        // Auto-scroll to bottom
        logContainer.scrollTop = logContainer.scrollHeight;
    }

    showErrorDetails(error) {
        // For development: show more detailed error information
        if (error.stack) {
            console.error('Full error details:', error.stack);
        }
        
        // Check if backend is reachable
        this.checkBackendHealth();
    }

    async checkBackendHealth() {
        try {
            const response = await this.callAPI('/health');
            this.addLogEntry('✅ Backend server is reachable');
        } catch (error) {
            this.addLogEntry('❌ Backend server is not reachable. Please ensure it\'s running on http://localhost:8000');
            this.addLogEntry('💡 Tip: Run `python -m uvicorn main:app --reload` in the backend directory');
        }
    }

    cancelScan() {
        if (this.currentScan) {
            this.updateStatus('⏹️ Scan cancelled by user', 'warning');
            this.addLogEntry('Scan cancelled by user (ESC pressed)');
            this.currentScan = null;
        }
    }
}

// Global functions for HTML onclick events
async function runDiscovery() {
    if (window.homieApp) {
        await window.homieApp.runDiscovery();
    }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.homieApp = new HomieApp();
});

// Add some global error handling
window.addEventListener('error', (event) => {
    console.error('Global error:', event.error);
    if (window.homieApp) {
        window.homieApp.addLogEntry(`⚠️ Unexpected error: ${event.error.message}`);
    }
});

// Handle unhandled promise rejections
window.addEventListener('unhandledrejection', (event) => {
    console.error('Unhandled promise rejection:', event.reason);
    if (window.homieApp) {
        window.homieApp.addLogEntry(`⚠️ Promise error: ${event.reason}`);
    }
});
