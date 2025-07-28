#!/usr/bin/env python3
"""
Homie API Server
Main Flask API server for the Homie ecosystem
Handles all module endpoints through a unified API
"""

import os
import sys
import time
import json
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

# Load environment variables first
print(f"[API Server] Current working directory: {os.getcwd()}")
print(f"[API Server] Looking for .env file at: {os.path.join(os.getcwd(), '.env')}")
print(f"[API Server] .env file exists: {os.path.exists('.env')}")
load_dotenv(override=True)
print(f"[API Server] After load_dotenv, RAIFFEISEN_CLIENT_ID: {repr(os.getenv('RAIFFEISEN_CLIENT_ID'))}")

# Add the current directory to the Python path for services imports
sys.path.insert(0, os.path.dirname(__file__))

from services.file_organizer import SmartOrganizer, discover_folders
from services.financial_manager import FinancialManager




app = Flask(__name__)
CORS(app)  # Enable CORS for frontend communication

# ============================================================================
# HEALTH & STATUS ENDPOINTS
# ============================================================================

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'message': 'Homie API is running!',
        'modules': ['file_organizer', 'financial_manager', 'raiffeisen_bank'],
        'version': '1.0.0'
    })

@app.route('/api/status', methods=['GET'])
def get_status():
    """Get system status and available modules"""
    return jsonify({
        'status': 'running',
        'version': '1.0.0',
        'modules': {
            'file_organizer': {
                'status': 'active',
                'endpoints': [
                    '/api/file-organizer/discover',
                    '/api/file-organizer/organize',
                    '/api/file-organizer/browse-folders'
                ]
            },
            'financial_manager': {
                'status': 'active',
                'endpoints': [
                    '/api/financial/summary',
                    '/api/financial/income',
                    '/api/financial/expenses',
                    '/api/financial/construction',
                    '/api/financial/tax-report'
                ]
            },
            'raiffeisen_bank': {
                'status': 'active',
                'endpoints': [
                    '/api/raiffeisen/auth/start',
                    '/api/raiffeisen/auth/callback',
                    '/api/raiffeisen/auth/status',
                    '/api/raiffeisen/sync',
                    '/api/raiffeisen/accounts',
                    '/api/raiffeisen/transactions'
                ]
            }
        },
        'endpoints': [
            '/api/health',
            '/api/status',
            '/api/file-organizer/*',
            '/api/financial/*',
            '/api/raiffeisen/*'
        ]
    })

# ============================================================================
# FILE ORGANIZER MODULE ENDPOINTS
# ============================================================================

@app.route('/api/file-organizer/discover', methods=['POST'])
def file_organizer_discover():
    """File Organizer: Folder discovery endpoint"""
    try:
        data = request.get_json()
        if not data or 'path' not in data:
            return jsonify({
                'success': False,
                'error': 'Path is required'
            }), 400
        
        scan_path = data['path']
        if not os.path.exists(scan_path):
            return jsonify({
                'success': False,
                'error': f'Path does not exist: {scan_path}'
            }), 400
        
        print(f"[File Organizer] Starting folder discovery for: {scan_path}")
        start_time = time.time()
        
        # Use the file organizer service
        folder_map = discover_folders(scan_path)
        
        end_time = time.time()
        scan_duration = end_time - start_time
        
        # Convert folder_map to the format expected by frontend
        folder_structure = {}
        total_files = 0
        
        for folder_path, folder_data in folder_map.items():
            folder_name = os.path.basename(folder_path) or folder_path
            file_count = len(folder_data.get('files', {}))
            total_files += file_count
            
            folder_structure[folder_name] = {
                'file_count': file_count,
                'subfolders': {}
            }
            
            # Add subdirectories from the dirs list
            for subdir_name in folder_data.get('dirs', []):
                folder_structure[folder_name]['subfolders'][subdir_name] = {
                    'file_count': 0
                }
        
        # Generate insights
        insights = []
        if len(folder_map) > 10:
            insights.append(f"Found {len(folder_map)} directories - quite a large structure!")
        if total_files > 1000:
            insights.append(f"Discovered {total_files} files total - substantial collection")
        if scan_duration > 5:
            insights.append(f"Scan took {scan_duration:.1f}s - consider optimizing for large directories")
        
        response_data = {
            'success': True,
            'data': {
                'total_folders': len(folder_map),
                'total_files': total_files,
                'scan_time': f"{scan_duration:.2f}s",
                'folder_structure': folder_structure,
                'insights': insights
            }
        }
        
        print(f"[File Organizer] ✅ Discovery completed: {len(folder_map)} folders, {total_files} files in {scan_duration:.2f}s")
        return jsonify(response_data)
        
    except Exception as e:
        print(f"[File Organizer] ❌ Error during discovery: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/file-organizer/organize', methods=['POST'])
def file_organizer_organize():
    """File Organizer: AI-powered smart organization analysis"""
    try:
        data = request.get_json()
        if not data or 'downloads_path' not in data or 'sorted_path' not in data:
            return jsonify({
                'success': False,
                'error': 'downloads_path and sorted_path are required'
            }), 400
        
        downloads_path = data['downloads_path']
        sorted_path = data['sorted_path']
        api_key = data.get('api_key')
        
        # If no API key provided, try to get it from environment
        if not api_key:
            from dotenv import load_dotenv
            load_dotenv()
            api_key = os.getenv('GEMINI_API_KEY')
            
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'Gemini API key is required for AI analysis. Please configure GEMINI_API_KEY in backend .env file'
            }), 400
        
        if not os.path.exists(downloads_path):
            return jsonify({
                'success': False,
                'error': f'Downloads path does not exist: {downloads_path}'
            }), 400
        
        if not os.path.exists(sorted_path):
            return jsonify({
                'success': False,
                'error': f'Sorted path does not exist: {sorted_path}'
            }), 400
        
        print(f"[File Organizer] 🤖 Starting AI organization analysis...")
        print(f"   Downloads: {downloads_path}")
        print(f"   Sorted: {sorted_path}")
        
        # Reuse existing organizer if same API key, otherwise create new one
        if (not hasattr(app, 'organizer_instance') or 
            app.organizer_instance is None or 
            getattr(app, 'organizer_api_key', None) != api_key):
            organizer = SmartOrganizer(api_key)
            app.organizer_instance = organizer
            app.organizer_api_key = api_key
        else:
            organizer = app.organizer_instance
        
        analysis = organizer.analyze_downloads_folder(downloads_path, sorted_path)
        
        # Check if the analysis contains quota or other API errors
        if 'error_type' in analysis:
            error_type = analysis['error_type']
            
            if error_type == 'quota_exceeded':
                print(f"[File Organizer] ⚠️  Quota exceeded during AI analysis")
                return jsonify({
                    'success': False,
                    'error_type': 'quota_exceeded',
                    'error': analysis['error'],
                    'error_details': analysis['error_details'],
                    'suggestions': analysis['suggestions'],
                    'quota_info': analysis.get('quota_info', {}),
                    'fallback_available': analysis.get('fallback_available', False)
                }), 429
                
            elif error_type == 'auth_error':
                print(f"[File Organizer] 🔑 Authentication error during AI analysis")
                return jsonify({
                    'success': False,
                    'error_type': 'auth_error',
                    'error': analysis['error'],
                    'error_details': analysis['error_details'],
                    'suggestions': analysis['suggestions']
                }), 401
                
            elif error_type == 'api_error':
                print(f"[File Organizer] 🔧 API error during AI analysis")
                return jsonify({
                    'success': False,
                    'error_type': 'api_error',
                    'error': analysis['error'],
                    'error_details': analysis['error_details'],
                    'suggestions': analysis['suggestions'],
                    'fallback_available': analysis.get('fallback_available', False)
                }), 502
                
            else:  # generic_error
                print(f"[File Organizer] ❌ Generic error during AI analysis")
                return jsonify({
                    'success': False,
                    'error_type': 'generic_error',
                    'error': analysis['error'],
                    'error_details': analysis['error_details'],
                    'suggestions': analysis['suggestions'],
                    'fallback_available': analysis.get('fallback_available', False)
                }), 500
        
        # Success case
        print(f"[File Organizer] ✅ AI analysis completed: {analysis['total_files']} files analyzed")
        
        return jsonify({
            'success': True,
            'data': analysis
        })
        
    except Exception as e:
        print(f"[File Organizer] ❌ Error during AI organization: {e}")
        return jsonify({
            'success': False,
            'error_type': 'server_error',
            'error': 'Server Error',
            'error_details': f'An unexpected server error occurred: {str(e)}',
            'suggestions': [
                'Try again in a few moments',
                'Check that all required parameters are provided',
                'Contact support if the problem persists'
            ]
        }), 500

@app.route('/api/file-organizer/execute-action', methods=['POST'])
def execute_file_action():
    """Execute a file action (move, delete, etc.)"""
    try:
        data = request.get_json()
        action = data.get('action')
        file_path = data.get('file_path')
        destination_path = data.get('destination_path')
        source_folder = data.get('source_folder')
        destination_folder = data.get('destination_folder')
        
        if not action or not file_path or not source_folder or not destination_folder:
            return jsonify({
                'success': False,
                'error': 'Missing required parameters'
            }), 400
        
        # Use environment API key
        from dotenv import load_dotenv
        load_dotenv()
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'GEMINI_API_KEY environment variable not set'
            }), 400
        
        # Initialize the organizer
        organizer = SmartOrganizer(api_key)
        
        # Execute the action
        result = organizer.execute_file_action(
            action=action,
            file_path=file_path,
            destination_path=destination_path,
            source_folder=source_folder,
            destination_folder=destination_folder
        )
        
        return jsonify({
            'success': True,
            'data': result
        })
        
    except Exception as e:
        print(f"Error executing file action: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/file-organizer/re-analyze', methods=['POST'])
def re_analyze_file():
    """Re-analyze a file with user input"""
    try:
        data = request.get_json()
        file_path = data.get('file_path')
        user_input = data.get('user_input')
        source_folder = data.get('source_folder')
        destination_folder = data.get('destination_folder')
        
        if not file_path or not user_input or not source_folder or not destination_folder:
            return jsonify({
                'success': False,
                'error': 'Missing required parameters'
            }), 400
        
        # Use environment API key
        from dotenv import load_dotenv
        load_dotenv()
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'GEMINI_API_KEY environment variable not set'
            }), 400
        
        # Initialize the organizer
        organizer = SmartOrganizer(api_key)
        
        # Re-analyze the file with user input
        result = organizer.re_analyze_file(
            file_path=file_path,
            user_input=user_input,
            source_folder=source_folder,
            destination_folder=destination_folder
        )
        
        return jsonify({
            'success': True,
            'data': result
        })
        
    except Exception as e:
        print(f"Error re-analyzing file: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/file-organizer/browse-folders', methods=['POST'])
def file_organizer_browse_folders():
    """File Organizer: Browse file system folders for path selection"""
    try:
        data = request.get_json()
        if not data or 'path' not in data:
            return jsonify({
                'success': False,
                'error': 'Path is required'
            }), 400
        
        browse_path = data['path']
        
        # Handle special case for root browsing
        if browse_path == '/':
            browse_path = '/'
        elif not os.path.exists(browse_path):
            return jsonify({
                'success': False,
                'error': f'Path does not exist: {browse_path}'
            }), 400
        
        items = []
        
        # Add parent directory option (except for root)
        if browse_path != '/':
            parent_path = os.path.dirname(browse_path)
            items.append({
                'name': '..',
                'path': parent_path,
                'type': 'parent',
                'is_directory': True
            })
        
        # List directories only
        try:
            for item_name in sorted(os.listdir(browse_path)):
                item_path = os.path.join(browse_path, item_name)
                
                # Only include directories and skip hidden files
                if os.path.isdir(item_path) and not item_name.startswith('.'):
                    items.append({
                        'name': item_name,
                        'path': item_path,
                        'type': 'directory',
                        'is_directory': True
                    })
        except PermissionError:
            return jsonify({
                'success': False,
                'error': f'Permission denied accessing: {browse_path}'
            }), 403
        
        return jsonify({
            'success': True,
            'data': {
                'current_path': browse_path,
                'items': items
            }
        })
        
    except Exception as e:
        print(f"[File Organizer] ❌ Error during folder browsing: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/file-organizer/destination-memory', methods=['GET'])
def file_organizer_destination_memory():
    """Return the current user's destination memory (folder mappings, usage, confidence, drives)"""
    try:
        # For now, use the dev user (future: get from auth/session)
        api_key = os.getenv('GEMINI_API_KEY', 'test_api_key')
        organizer = SmartOrganizer(api_key=api_key)
        memory = organizer.get_destination_memory()
        drives = organizer.discover_available_drives()
        
        response = {
            'success': True,
            'data': {
                'destination_memory': memory,
                'available_drives': drives
            }
        }
        return jsonify(response)
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ============================================================================
# FINANCIAL MANAGER MODULE ENDPOINTS
# ============================================================================

# Initialize financial manager
financial_manager = FinancialManager()

@app.route('/api/financial/summary', methods=['GET'])
def financial_summary():
    """Get financial summary with optional time period filtering"""
    try:
        # Initialize sub-managers if not already done
        if not financial_manager.income_tracker:
            financial_manager.initialize_sub_managers()
        
        # Get query parameters for time period filtering
        year = request.args.get('year', type=int)
        month = request.args.get('month', type=int)
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        # Get summary data with period filtering
        summary_data = financial_manager.get_financial_summary(
            year=year, 
            month=month, 
            start_date=start_date, 
            end_date=end_date
        )
        
        # Convert to dict for JSON serialization
        summary_dict = {
            'total_employment_income': summary_data.total_employment_income,
            'total_self_employment_income': summary_data.total_self_employment_income,
            'total_expenses': summary_data.total_expenses,
            'total_tax_liability': summary_data.total_tax_liability,
            'construction_budget_used': summary_data.construction_budget_used,
            'construction_budget_remaining': summary_data.construction_budget_remaining,
            'net_balance': summary_data.net_balance,
            'monthly_cash_flow': summary_data.monthly_cash_flow,
            'main_account_balance': summary_data.main_account_balance,
            'sparkonto_balance': summary_data.sparkonto_balance,
            'cash_on_hand': summary_data.cash_on_hand,
            'cash_account_balance': summary_data.cash_account_balance,
            'aktien_balance': summary_data.aktien_balance,
            'fonds_balance': summary_data.fonds_balance,
            'total_transfers_from_sparkonto': summary_data.total_transfers_from_sparkonto,
            'total_investment_value': summary_data.total_investment_value
        }
        
        return jsonify({
            'success': True,
            'data': summary_dict
        })
        
    except Exception as e:
        print(f"[Financial] ❌ Error getting summary: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# Account Management Endpoints
@app.route('/api/financial/accounts', methods=['GET', 'POST'])
def financial_accounts():
    """Get all user accounts or create a new account"""
    try:
        if request.method == 'GET':
            # Get all user-created accounts
            accounts = financial_manager.get_user_accounts()
            return jsonify({
                'success': True,
                'data': accounts
            })
        
        elif request.method == 'POST':
            # Create new account
            data = request.get_json()
            if not data:
                return jsonify({'success': False, 'error': 'No data provided'}), 400
            
            name = data.get('name')
            account_type = data.get('type', 'checking')  # checking, savings, investment, cash
            initial_balance = float(data.get('initial_balance', 0))
            
            if not name:
                return jsonify({'success': False, 'error': 'Account name is required'}), 400
            
            success = financial_manager.create_user_account(name, account_type, initial_balance)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': f'Account "{name}" created successfully'
                })
            else:
                return jsonify({'success': False, 'error': 'Failed to create account'}), 500
                
    except Exception as e:
        print(f"[Financial] ❌ Error with accounts: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/accounts/<account_id>', methods=['DELETE'])
def delete_account(account_id):
    """Delete a user account"""
    try:
        success = financial_manager.delete_user_account(account_id)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Account deleted successfully'
            })
        else:
            return jsonify({'success': False, 'error': 'Failed to delete account or account not found'}), 404
            
    except Exception as e:
        print(f"[Financial] ❌ Error deleting account: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# Legacy account balance endpoints (for backwards compatibility)
@app.route('/api/financial/legacy-accounts', methods=['GET'])
def financial_legacy_accounts():
    """Get legacy account balances"""
    try:
        accounts = {
            'main': financial_manager.get_account_balance('main'),
            'sparkonto': financial_manager.get_account_balance('sparkonto'),
            'cash_on_hand': financial_manager.get_account_balance('cash_on_hand'),
            'cash_account': financial_manager.get_account_balance('cash_account'),
            'aktien': financial_manager.get_account_balance('aktien'),
            'fonds': financial_manager.get_account_balance('fonds')
        }
        
        return jsonify({
            'success': True,
            'data': accounts
        })
        
    except Exception as e:
        print(f"[Financial] ❌ Error getting account balances: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/accounts/<account_type>/balance', methods=['POST'])
def set_account_balance(account_type):
    """Set account balance (for initial setup)"""
    try:
        data = request.get_json()
        if not data or 'balance' not in data:
            return jsonify({'success': False, 'error': 'Balance not provided'}), 400
        
        balance = float(data['balance'])
        manual_balance_date = data.get('manual_balance_date')  # Optional date when balance was set
        
        financial_manager.set_account_balance(account_type, balance, manual_balance_date)
        
        date_info = f" as of {manual_balance_date}" if manual_balance_date else ""
        return jsonify({
            'success': True,
            'message': f'{account_type} balance set to €{balance:.2f}{date_info}'
        })
        
    except Exception as e:
        print(f"[Financial] ❌ Error setting account balance: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# Securities/Investment Management
@app.route('/api/financial/securities', methods=['GET', 'POST'])
def financial_securities():
    """Get securities portfolio or add new security"""
    try:
        if request.method == 'GET':
            # Get all securities
            securities = financial_manager.get_securities_portfolio()
            return jsonify({
                'success': True,
                'data': securities
            })
        
        elif request.method == 'POST':
            # Add new security
            data = request.get_json()
            if not data:
                return jsonify({'success': False, 'error': 'No data provided'}), 400
            
            symbol = data.get('symbol')
            name = data.get('name')
            quantity = float(data.get('quantity', 0))
            purchase_price = float(data.get('purchase_price', 0))
            purchase_date = data.get('purchase_date')  # Optional purchase date
            
            if not symbol or not name:
                return jsonify({'success': False, 'error': 'Symbol and name are required'}), 400
            
            success = financial_manager.add_security(symbol, name, quantity, purchase_price, purchase_date)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': f'Security "{symbol}" added successfully'
                })
            else:
                return jsonify({'success': False, 'error': 'Failed to add security'}), 500
                
    except Exception as e:
        print(f"[Financial] ❌ Error with securities: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/securities/<symbol>/price', methods=['GET'])
def get_security_price(symbol):
    """Get current price for a security"""
    try:
        price_data = financial_manager.get_security_current_price(symbol)
        
        if price_data:
            return jsonify({
                'success': True,
                'data': price_data
            })
        else:
            return jsonify({'success': False, 'error': 'Failed to fetch price data'}), 404
            
    except Exception as e:
        print(f"[Financial] ❌ Error getting security price: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/securities/<symbol>/history', methods=['GET'])
def get_security_history(symbol):
    """Get price history for a security"""
    try:
        days = request.args.get('days', 30, type=int)
        history_data = financial_manager.get_security_price_history(symbol, days)
        
        if history_data:
            return jsonify({
                'success': True,
                'data': history_data
            })
        else:
            return jsonify({'success': False, 'error': 'Failed to fetch price history'}), 404
            
    except Exception as e:
        print(f"[Financial] ❌ Error getting security history: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/securities/<security_id>', methods=['DELETE'])
def delete_security(security_id):
    """Delete a security from portfolio"""
    try:
        success = financial_manager.delete_security(security_id)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Security deleted successfully'
            })
        else:
            return jsonify({'success': False, 'error': 'Failed to delete security or security not found'}), 404
            
    except Exception as e:
        print(f"[Financial] ❌ Error deleting security: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/securities/lookup', methods=['POST'])
def lookup_security():
    """AI-powered security symbol lookup"""
    try:
        data = request.get_json()
        if not data or 'query' not in data:
            return jsonify({'success': False, 'error': 'Search query not provided'}), 400
        
        search_query = data.get('query', '').strip()
        if not search_query:
            return jsonify({'success': False, 'error': 'Search query cannot be empty'}), 400
        
        result = financial_manager.lookup_security_symbol(search_query)
        
        return jsonify(result)
        
    except Exception as e:
        print(f"[Financial] ❌ Error in security lookup: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/income', methods=['GET', 'POST'])
def financial_income():
    """Handle income operations"""
    try:
        if request.method == 'GET':
            # Get income data
            year = request.args.get('year', datetime.now().year, type=int)
            
            if not financial_manager.income_tracker:
                financial_manager.initialize_sub_managers()
            
            data = {
                'employment_total': financial_manager.income_tracker.get_employment_total(year),
                'self_employment_total': financial_manager.income_tracker.get_self_employment_total(year),
                'monthly_breakdown': financial_manager.income_tracker.get_monthly_breakdown(year),
                'recent_income': financial_manager.income_tracker.get_recent_income()
            }
            
            return jsonify({
                'success': True,
                'data': data
            })
            
        elif request.method == 'POST':
            # Add new income
            data = request.get_json()
            if not data:
                return jsonify({'success': False, 'error': 'No data provided'}), 400
            
            income_type = data.get('type')
            amount = data.get('amount')
            date = data.get('date')
            
            if income_type == 'employment':
                employer = data.get('employer')
                description = data.get('description')
                success = financial_manager.add_employment_income(amount, date, employer, description)
            elif income_type == 'self_employment':
                client = data.get('client')
                description = data.get('description')
                invoice_number = data.get('invoice_number')
                success = financial_manager.add_self_employment_income(amount, date, client, description, invoice_number)
            else:
                return jsonify({'success': False, 'error': 'Invalid income type'}), 400
            
            if success:
                return jsonify({'success': True, 'message': 'Income added successfully'})
            else:
                return jsonify({'success': False, 'error': 'Failed to add income'}), 500
                
    except Exception as e:
        print(f"[Financial] ❌ Error with income: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/expenses', methods=['GET', 'POST'])
def financial_expenses():
    """Handle expense operations"""
    try:
        if request.method == 'GET':
            year = request.args.get('year', datetime.now().year, type=int)
            
            if not financial_manager.expense_manager:
                financial_manager.initialize_sub_managers()
            
            data = {
                'total_expenses': financial_manager.expense_manager.get_total_expenses(year),
                'deductible_expenses': financial_manager.expense_manager.get_deductible_expenses(year),
                'expenses_by_category': financial_manager.expense_manager.get_expenses_by_category(year),
                'categories': financial_manager.expense_manager.categories
            }
            
            return jsonify({
                'success': True,
                'data': data
            })
            
        elif request.method == 'POST':
            data = request.get_json()
            if not data:
                return jsonify({'success': False, 'error': 'No data provided'}), 400
            
            amount = data.get('amount')
            date = data.get('date')
            category = data.get('category')
            description = data.get('description')
            receipt_path = data.get('receipt_path')
            
            success = financial_manager.add_expense(amount, date, category, description, receipt_path)
            
            if success:
                return jsonify({'success': True, 'message': 'Expense added successfully'})
            else:
                return jsonify({'success': False, 'error': 'Failed to add expense'}), 500
                
    except Exception as e:
        print(f"[Financial] ❌ Error with expenses: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/construction', methods=['GET', 'POST'])
def financial_construction():
    """Handle construction budget operations"""
    try:
        if request.method == 'GET':
            if not financial_manager.construction_budget:
                financial_manager.initialize_sub_managers()
            
            data = {
                'budget_status': financial_manager.construction_budget.get_budget_status(),
                'spending_by_category': financial_manager.construction_budget.get_spending_by_category(),
                'categories': financial_manager.construction_budget.categories
            }
            
            return jsonify({
                'success': True,
                'data': data
            })
            
        elif request.method == 'POST':
            data = request.get_json()
            if not data:
                return jsonify({'success': False, 'error': 'No data provided'}), 400
            
            amount = data.get('amount')
            date = data.get('date')
            category = data.get('category')
            vendor = data.get('vendor')
            description = data.get('description')
            receipt_path = data.get('receipt_path')
            
            success = financial_manager.add_construction_expense(amount, date, category, vendor, description, receipt_path)
            
            if success:
                return jsonify({'success': True, 'message': 'Construction expense added successfully'})
            else:
                return jsonify({'success': False, 'error': 'Failed to add construction expense'}), 500
                
    except Exception as e:
        print(f"[Financial] ❌ Error with construction: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/tax-report', methods=['GET'])
def financial_tax_report():
    """Get Austrian tax report"""
    try:
        year = request.args.get('year', datetime.now().year, type=int)
        tax_report = financial_manager.get_tax_report(year)
        
        return jsonify({
            'success': True,
            'data': tax_report
        })
        
    except Exception as e:
        print(f"[Financial] ❌ Error generating tax report: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/monthly-report', methods=['GET'])
def financial_monthly_report():
    """Get monthly financial report"""
    try:
        year = request.args.get('year', datetime.now().year, type=int)
        month = request.args.get('month', datetime.now().month, type=int)
        
        monthly_report = financial_manager.get_monthly_report(year, month)
        
        return jsonify({
            'success': True,
            'data': monthly_report.__dict__
        })
        
    except Exception as e:
        print(f"[Financial] ❌ Error generating monthly report: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/transactions', methods=['GET'])
def financial_transactions():
    """Get transaction details for a period"""
    try:
        year = request.args.get('year', datetime.now().year, type=int)
        month = request.args.get('month', type=int)
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        limit = request.args.get('limit', 50, type=int)
        
        transactions = financial_manager.get_transactions_for_period(
            start_date=start_date,
            end_date=end_date,
            year=year,
            month=month
        )
        
        # Limit results
        transactions = transactions[:limit]
        
        return jsonify({
            'success': True,
            'data': [transaction.__dict__ for transaction in transactions],
            'total_count': len(transactions)
        })
        
    except Exception as e:
        print(f"[Financial] ❌ Error getting transactions: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/cash-expense', methods=['POST'])
def add_cash_expense():
    """Add cash expense (e.g., construction worker payment)"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400
        
        amount = float(data.get('amount', 0))
        date = data.get('date')
        description = data.get('description', '')
        category = data.get('category', 'Construction')
        
        if amount <= 0 or not date or not description:
            return jsonify({'success': False, 'error': 'Invalid data provided'}), 400
        
        success = financial_manager.record_cash_expense(amount, date, description, category)
        
        if success:
            return jsonify({'success': True, 'message': 'Cash expense recorded successfully'})
        else:
            return jsonify({'success': False, 'error': 'Failed to record cash expense'}), 500
        
    except Exception as e:
        print(f"[Financial] ❌ Error adding cash expense: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/investment/<investment_type>', methods=['POST'])
def manage_investment(investment_type):
    """Manage investment (purchase, sale, or value update)"""
    try:
        if investment_type not in ['aktien', 'fonds']:
            return jsonify({'success': False, 'error': 'Invalid investment type'}), 400
        
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400
        
        action = data.get('action')  # 'purchase', 'sale', 'update_value'
        amount = float(data.get('amount', 0))
        date = data.get('date')
        description = data.get('description', '')
        
        if action == 'purchase':
            success = financial_manager.record_investment_purchase(amount, date, investment_type, description)
            message = f'{investment_type.title()} purchase recorded successfully'
        elif action == 'sale':
            success = financial_manager.record_investment_sale(amount, date, investment_type, description)
            message = f'{investment_type.title()} sale recorded successfully'
        elif action == 'update_value':
            success = financial_manager.update_investment_value(investment_type, amount)
            message = f'{investment_type.title()} value updated successfully'
        else:
            return jsonify({'success': False, 'error': 'Invalid action'}), 400
        
        if success:
            return jsonify({'success': True, 'message': message})
        else:
            return jsonify({'success': False, 'error': f'Failed to {action} {investment_type}'}), 500
        
    except Exception as e:
        print(f"[Financial] ❌ Error managing investment: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/cash-account/transfer', methods=['POST'])
def cash_account_transfer():
    """Transfer between cash account and main account"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400
        
        amount = float(data.get('amount', 0))
        date = data.get('date')
        description = data.get('description', '')
        to_main = data.get('to_main', True)  # True = cash_account -> main, False = main -> cash_account
        
        if amount <= 0 or not date or not description:
            return jsonify({'success': False, 'error': 'Invalid data provided'}), 400
        
        success = financial_manager.record_cash_account_transfer(amount, date, description, to_main)
        
        direction = 'to main account' if to_main else 'to cash account'
        if success:
            return jsonify({'success': True, 'message': f'Cash account transfer {direction} recorded successfully'})
        else:
            return jsonify({'success': False, 'error': 'Failed to record cash account transfer'}), 500
        
    except Exception as e:
        print(f"[Financial] ❌ Error with cash account transfer: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/financial/import-csv', methods=['POST'])
def financial_import_csv():
    """Import bank transactions from CSV file"""
    try:
        # Handle file upload
        if 'file' not in request.files:
            return jsonify({'success': False, 'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No file selected'}), 400
        
        if not file.filename.lower().endswith('.csv'):
            return jsonify({'success': False, 'error': 'File must be a CSV file'}), 400
        
        # Get account type from request (main or sparkonto)
        account_type = request.form.get('account_type', 'main')  # Default to main account
        if account_type not in ['main', 'sparkonto']:
            return jsonify({'success': False, 'error': 'Invalid account type'}), 400
        
        # Read CSV content
        import csv
        import io
        
        # Decode file content
        content = file.read().decode('utf-8')
        csv_data = []
        
        # Parse CSV - handle both header and headerless formats
        csv_reader = csv.reader(io.StringIO(content), delimiter=';')
        rows = list(csv_reader)
        
        if not rows:
            return jsonify({'success': False, 'error': 'CSV file is empty'}), 400
        
        # Check if first row looks like Raiffeisen format (no headers, 6 columns)
        first_row = rows[0]
        if len(first_row) == 6 and first_row[0].count('.') == 2:  # Date format DD.MM.YYYY
            # Raiffeisen format: booking_date;description;transaction_date;amount;currency;timestamp
            print(f"[CSV Import] Detected Raiffeisen format for {account_type} account")
            for row in rows:
                if len(row) >= 4:  # Need at least date, description, transaction_date, amount
                    csv_data.append({
                        'date': row[2],  # Use transaction date (column 3)
                        'description': row[1],  # Description (column 2)
                        'amount': row[3],  # Amount (column 4)
                        'currency': row[4] if len(row) > 4 else 'EUR',
                        'account_type': account_type
                    })
        else:
            # Standard CSV with headers
            print(f"[CSV Import] Detected standard CSV format for {account_type} account")
            csv_reader = csv.DictReader(io.StringIO(content))
            for row in csv_reader:
                row['account_type'] = account_type
                csv_data.append(row)
        
        if not csv_data:
            return jsonify({'success': False, 'error': 'No valid transactions found in CSV'}), 400
        
        # Process transactions
        processed_transactions = []
        skipped_transactions = []
        duplicate_count = 0
        
        for row in csv_data:
            try:
                # Extract fields from standardized format
                date = row.get('date', '')
                amount_str = row.get('amount', '')
                description = row.get('description', '')
                
                # Convert date from DD.MM.YYYY to YYYY-MM-DD
                if date and '.' in date:
                    try:
                        day, month, year = date.split('.')
                        date = f"{year}-{month.zfill(2)}-{day.zfill(2)}"
                    except ValueError:
                        print(f"[CSV Import] Invalid date format: {date}")
                        continue
                
                # Parse amount (handle comma decimal separator)
                amount = None
                if amount_str:
                    try:
                        # Handle different decimal separators and remove currency symbols
                        amount_str = amount_str.replace(',', '.').replace('€', '').replace('EUR', '').strip()
                        amount = float(amount_str)
                    except (ValueError, TypeError):
                        print(f"[CSV Import] Invalid amount format: {amount_str}")
                        continue
                
                # Skip if essential fields are missing
                if not date or amount is None or not description:
                    skipped_transactions.append({
                        'row': row,
                        'reason': f'Missing required fields: date={bool(date)}, amount={amount is not None}, description={bool(description)}'
                    })
                    continue
                
                # Get account type for this transaction
                current_account = row.get('account_type', 'main')
                
                # Check if transaction should be processed based on manual balance date
                account_balance = financial_manager.account_balances.get(current_account)
                if account_balance and account_balance.manual_balance_date:
                    # Skip transactions that occurred before the manual balance date
                    if date <= account_balance.manual_balance_date:
                        skipped_transactions.append({
                            'row': row,
                            'reason': f'Transaction date {date} is before manual balance date {account_balance.manual_balance_date}'
                        })
                        continue
                
                # Determine transaction type and add to appropriate category
                if amount > 0:
                    if current_account == 'sparkonto':
                        # Sparkonto positive transaction (deposit, interest, etc.)
                        desc_lower = description.lower()
                        if any(keyword in desc_lower for keyword in ['zinsen', 'zins', 'interest']):
                            category = 'Interest'
                        elif any(keyword in desc_lower for keyword in ['einzahlung', 'deposit']):
                            category = 'Deposit'
                        else:
                            category = 'Sparkonto Income'
                        
                        # Record transaction in Sparkonto account
                        success = financial_manager.add_transaction(
                            amount=amount,
                            date=date,
                            description=description,
                            category=category,
                            account_from='external',
                            account_to='sparkonto',
                            transaction_type='income'
                        )
                        # Update Sparkonto balance
                        financial_manager._update_account_balance('sparkonto', amount)
                    else:
                        # Main account positive transaction
                        desc_lower = description.lower()
                        if any(keyword in desc_lower for keyword in ['sparkonto', 'sparbuch', 'übertrag', 'transfer']):
                            # This is a transfer from savings account
                            success = financial_manager.record_sparkonto_transfer(amount, date, description)
                        else:
                            # Regular income transaction
                            success = financial_manager.add_employment_income(amount, date, 'CSV Import', description)
                            # Also record the transaction detail
                            financial_manager.add_transaction(
                                amount=amount,
                                date=date,
                                description=description,
                                category='Employment Income',
                                account_from='external',
                                account_to='main',
                                transaction_type='income'
                            )
                else:
                    # Negative amount transaction
                    abs_amount = abs(amount)
                    
                    if current_account == 'sparkonto':
                        # Sparkonto negative transaction (withdrawal, transfer to main)
                        desc_lower = description.lower()
                        if any(keyword in desc_lower for keyword in ['übertrag', 'transfer', 'hauptkonto']):
                            category = 'Transfer to Main Account'
                            # Record transfer from Sparkonto to main
                            success = financial_manager.add_transaction(
                                amount=abs_amount,
                                date=date,
                                description=description,
                                category=category,
                                account_from='sparkonto',
                                account_to='main',
                                transaction_type='transfer'
                            )
                            # Update balances
                            financial_manager._update_account_balance('sparkonto', -abs_amount)
                            financial_manager._update_account_balance('main', abs_amount)
                        else:
                            category = 'Sparkonto Withdrawal'
                            success = financial_manager.add_transaction(
                                amount=abs_amount,
                                date=date,
                                description=description,
                                category=category,
                                account_from='sparkonto',
                                account_to='external',
                                transaction_type='expense'
                            )
                            # Update Sparkonto balance
                            financial_manager._update_account_balance('sparkonto', -abs_amount)
                    else:
                        # Main account expense transaction
                        # Enhanced categorization for Austrian businesses
                        category = 'Other'
                        desc_lower = description.lower()
                        
                        # Check for cash withdrawal first
                        if any(keyword in desc_lower for keyword in ['behebung', 'bargeld', 'cash', 'abhebung']):
                            category = 'Cash Withdrawal'
                            success = financial_manager.record_cash_withdrawal(abs_amount, date, description)
                        # Construction & Hardware
                        elif any(keyword in desc_lower for keyword in ['bauhaus', 'hornbach', 'obi', 'baumax', 'bau', 'fenster', 'installateur']):
                            category = 'Construction'
                            success = financial_manager.add_construction_expense(abs_amount, date, 'Materials', 'CSV Import', description)
                        # Food & Dining
                        elif any(keyword in desc_lower for keyword in ['billa', 'spar', 'hofer', 'lieb markt', 'merkur', 'restaurant', 'gasthaus']):
                            category = 'Food & Dining'
                            success = financial_manager.add_expense(abs_amount, date, category, description)
                        # Transportation
                        elif any(keyword in desc_lower for keyword in ['tankstelle', 'shell', 'bp', 'omv', 'eni', 'gas', 'fuel']):
                            category = 'Transportation'
                            success = financial_manager.add_expense(abs_amount, date, category, description)
                        # Utilities & Services
                        elif any(keyword in desc_lower for keyword in ['a1 telekom', 'energie', 'strom', 'gas', 'wasser', 'internet']):
                            category = 'Utilities'
                            success = financial_manager.add_expense(abs_amount, date, category, description)
                        # Banking & Finance
                        elif any(keyword in desc_lower for keyword in ['überweisung', 'online banking', 'gebühr']):
                            category = 'Banking'
                            success = financial_manager.add_expense(abs_amount, date, category, description)
                        else:
                            success = financial_manager.add_expense(abs_amount, date, category, description)
                        
                        # Record transaction detail for expenses (except cash withdrawal which is handled above)
                        if category != 'Cash Withdrawal':
                            financial_manager.add_transaction(
                                amount=abs_amount,
                                date=date,
                                description=description,
                                category=category,
                                account_from='main',
                                account_to='external',
                                transaction_type='expense'
                            )
                
                if success:
                    processed_transactions.append({
                        'date': date,
                        'amount': amount,
                        'description': description,
                        'category': category if amount < 0 else 'Income'
                    })
                else:
                    # Check if it's a duplicate (success=False due to duplicate detection)
                    if 'Duplicate' in str(row.get('reason', '')):
                        duplicate_count += 1
                        skipped_transactions.append({
                            'row': row,
                            'reason': 'Duplicate transaction (already exists)'
                        })
                    else:
                        skipped_transactions.append({
                            'row': row,
                            'reason': 'Failed to save transaction (possibly duplicate)'
                        })
                    
            except Exception as e:
                skipped_transactions.append({
                    'row': row,
                    'reason': f'Processing error: {str(e)}'
                })
        
        # Get manual balance date info for response
        account_balance = financial_manager.account_balances.get(account_type)
        manual_balance_date = account_balance.manual_balance_date if account_balance else None
        
        # Count transactions skipped due to date filtering
        date_filtered_count = sum(1 for t in skipped_transactions 
                                 if 'before manual balance date' in t.get('reason', ''))
        
        return jsonify({
            'success': True,
            'message': f'CSV import completed for {account_type} account',
            'account_type': account_type,
            'manual_balance_date': manual_balance_date,
            'total_rows': len(csv_data),
            'added_income': sum(1 for t in processed_transactions if t['category'] in ['Income', 'Interest', 'Deposit', 'Sparkonto Income', 'Employment Income']),
            'added_expenses': sum(1 for t in processed_transactions if t['category'] not in ['Income', 'Interest', 'Deposit', 'Sparkonto Income', 'Employment Income', 'Construction', 'Transfer to Main Account', 'Transfer from Sparkonto']),
            'added_construction': sum(1 for t in processed_transactions if t['category'] == 'Construction'),
            'added_transfers': sum(1 for t in processed_transactions if t['category'] in ['Transfer to Main Account', 'Transfer from Sparkonto']),
            'skipped': len(skipped_transactions),
            'skipped_due_to_date': date_filtered_count,
            'duplicates': duplicate_count,
            'processed_transactions': processed_transactions,
            'skipped_transactions': skipped_transactions[:5]  # Show first 5 skipped for debugging
        })
        
    except Exception as e:
        print(f"[Financial] ❌ Error importing CSV: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ============================================================================
# FILE ACCESS TRACKING ENDPOINTS
# ============================================================================

@app.route('/api/file-organizer/log-access', methods=['POST'])
def log_file_access():
    """Log file access for usage tracking"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400
        
        file_path = data.get('file_path')
        action = data.get('action', 'open')
        user_agent = data.get('user_agent')
        
        if not file_path:
            return jsonify({'success': False, 'error': 'file_path is required'}), 400
        
        # Initialize smart organizer
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            return jsonify({'success': False, 'error': 'Gemini API key not configured'}), 500
        
        organizer = SmartOrganizer(api_key)
        result = organizer.log_file_access(file_path, action, user_agent)
        
        if result['success']:
            return jsonify(result)
        else:
            return jsonify(result), 400
            
    except Exception as e:
        print(f"[File Access] ❌ Error logging access: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/file-organizer/access-analytics', methods=['GET'])
def get_file_access_analytics():
    """Get file access analytics for a folder"""
    try:
        folder_path = request.args.get('folder_path')
        days = request.args.get('days', 30, type=int)
        
        if not folder_path:
            return jsonify({'success': False, 'error': 'folder_path parameter is required'}), 400
        
        if not os.path.exists(folder_path):
            return jsonify({'success': False, 'error': f'Folder not found: {folder_path}'}), 404
        
        # Initialize smart organizer
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            return jsonify({'success': False, 'error': 'Gemini API key not configured'}), 500
        
        organizer = SmartOrganizer(api_key)
        result = organizer.get_file_access_analytics(folder_path, days)
        
        return jsonify(result)
        
    except Exception as e:
        print(f"[File Access] ❌ Error getting analytics: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ============================================================================
# FUTURE MODULE ENDPOINTS
# ============================================================================

# TODO: Add media manager endpoints (/api/media/*)
# TODO: Add document manager endpoints (/api/documents/*)

if __name__ == '__main__':
    print("🏠 Starting Homie API Server...")
    print("=" * 60)
    print("Frontend should connect to: http://localhost:8000")
    print("Available modules and endpoints:")
    print("  📂 File Organizer:")
    print("    POST /api/file-organizer/discover")
    print("    POST /api/file-organizer/organize")
    print("    POST /api/file-organizer/execute-action")
    print("    POST /api/file-organizer/re-analyze")
    print("    POST /api/file-organizer/browse-folders")
    print("    POST /api/file-organizer/log-access")
    print("    GET  /api/file-organizer/access-analytics")
    print("  💰 Financial Manager:")
    print("    GET  /api/financial/summary")
    print("    GET/POST /api/financial/income")
    print("    GET/POST /api/financial/expenses")
    print("    GET/POST /api/financial/construction")
    print("    GET  /api/financial/tax-report")
    print("    POST /api/financial/import-csv")
    print("  🔧 System:")
    print("    GET  /api/health")
    print("    GET  /api/status")
    print("-" * 60)
    print("🚀 Starting server on http://localhost:8000")
    
    app.run(host='0.0.0.0', port=8000, debug=True)
