#!/usr/bin/env python3
"""
Homie API Server
Main Flask API server for the Homie ecosystem
Handles all module endpoints through a unified API
"""

import os
import sys
import time
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

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
        'modules': ['file_organizer', 'financial_manager'],  # List available modules
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
            }
        },
        'endpoints': [
            '/api/health',
            '/api/status',
            '/api/file-organizer/*',
            '/api/financial/*'
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
        
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'Gemini API key is required for AI analysis'
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

# ============================================================================
# FINANCIAL MANAGER MODULE ENDPOINTS
# ============================================================================

# Initialize financial manager
financial_manager = FinancialManager()

@app.route('/api/financial/summary', methods=['GET'])
def financial_summary():
    """Get financial summary and overview"""
    try:
        year = request.args.get('year', datetime.now().year, type=int)
        summary = financial_manager.get_financial_summary(year)
        
        return jsonify({
            'success': True,
            'data': summary.__dict__
        })
        
    except Exception as e:
        print(f"[Financial] ❌ Error getting summary: {e}")
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
    print("    POST /api/file-organizer/browse-folders")
    print("  💰 Financial Manager:")
    print("    GET  /api/financial/summary")
    print("    GET/POST /api/financial/income")
    print("    GET/POST /api/financial/expenses")
    print("    GET/POST /api/financial/construction")
    print("    GET  /api/financial/tax-report")
    print("  🔧 System:")
    print("    GET  /api/health")
    print("    GET  /api/status")
    print("-" * 60)
    print("🚀 Starting server on http://localhost:8000")
    
    app.run(host='0.0.0.0', port=8000, debug=True)
