#!/usr/bin/env python3
"""
File Organizer Routes - Core organization endpoints
Handles: organize, execute, add-granularity
"""

import logging
from flask import request, jsonify
from pathlib import Path

logger = logging.getLogger('FileOrganizerRoutes')


def register_file_organizer_routes(app, web_server):
    """Register file organizer routes with the Flask app"""
    
    def _execute_single_step(step, source_path):
        """Execute a single step of a file plan. Returns (success, error_message)"""
        import shutil
        import os
        
        step_type = step['type']
        target_path = step.get('target_path')
        
        try:
            if step_type == 'delete':
                os.remove(source_path)
                logger.info(f"Deleted: {source_path}")
                return True, None
                
            elif step_type == 'unpack':
                dest_dir = Path(target_path)
                dest_dir.mkdir(parents=True, exist_ok=True)
                
                file_ext = Path(source_path).suffix.lower()
                if file_ext == '.zip':
                    import zipfile
                    with zipfile.ZipFile(source_path, 'r') as zf:
                        zf.extractall(dest_dir)
                elif file_ext == '.rar':
                    try:
                        import rarfile
                        with rarfile.RarFile(source_path, 'r') as rf:
                            rf.extractall(dest_dir)
                    except ImportError:
                        return False, "RAR support not available"
                elif file_ext == '.7z':
                    try:
                        import py7zr
                        with py7zr.SevenZipFile(source_path, 'r') as szf:
                            szf.extractall(dest_dir)
                    except ImportError:
                        return False, "7z support not available"
                else:
                    return False, f"Unsupported archive format: {file_ext}"
                
                logger.info(f"Unpacked {source_path} to {dest_dir}")
                return True, None
                
            elif step_type == 'move':
                dest_dir = Path(target_path).parent
                dest_dir.mkdir(parents=True, exist_ok=True)
                shutil.move(source_path, target_path)
                logger.info(f"Moved {source_path} to {target_path}")
                return True, None
                
            elif step_type == 'copy':
                dest_dir = Path(target_path).parent
                dest_dir.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source_path, target_path)
                logger.info(f"Copied {source_path} to {target_path}")
                return True, None
                
            elif step_type == 'rename':
                dest_dir = Path(target_path).parent
                dest_dir.mkdir(parents=True, exist_ok=True)
                shutil.move(source_path, target_path)
                logger.info(f"Renamed {source_path} to {target_path}")
                return True, None
                
            else:
                return False, f"Unknown step type: {step_type}"
                
        except Exception as e:
            logger.error(f"Step execution error: {e}")
            return False, str(e)
    
    def _execute_file_plans(data, analysis_id, file_plans, web_server):
        """Execute file plans with multi-step atomic operations per file.
        Supports nested plans for extracted archive contents."""
        from datetime import datetime
        import json
        
        user_id = data.get('user_id', 'dev_user')
        client_id = data.get('client_id', 'default_client')
        
        plan_results = []
        successful_files = 0
        failed_files = 0
        
        for plan in file_plans:
            source = plan['source']
            steps = plan['steps']
            nested_plans = plan.get('nested_plans', [])
            
            plan_result = {
                'source': source,
                'success': True,
                'steps': [],
                'nested_results': []
            }
            
            # Execute steps sequentially - stop on first failure
            current_path = source
            for step in sorted(steps, key=lambda s: s['order']):
                step_result = {
                    'operation_id': step['operation_id'],
                    'type': step['type'],
                    'order': step['order'],
                    'success': False,
                    'error': None
                }
                
                success, error = _execute_single_step(step, current_path)
                step_result['success'] = success
                step_result['error'] = error
                
                plan_result['steps'].append(step_result)
                
                if not success:
                    # Step failed - stop executing this plan
                    plan_result['success'] = False
                    plan_result['error'] = f"Step {step['order']} failed: {error}"
                    logger.error(f"Plan failed for {source} at step {step['order']}: {error}")
                    break
                
                # Update current path for next step (if file was moved/renamed)
                if step['type'] in ['move', 'rename', 'copy']:
                    current_path = step['target_path']
            
            # Execute nested plans (for extracted files) if parent succeeded
            if plan_result['success'] and nested_plans:
                logger.info(f"Executing {len(nested_plans)} nested operations for extracted files")
                
                for nested_plan in nested_plans:
                    nested_source = nested_plan['source']
                    nested_steps = nested_plan['steps']
                    
                    nested_result = {
                        'source': nested_source,
                        'success': True,
                        'steps': []
                    }
                    
                    nested_current_path = nested_source
                    for nested_step in sorted(nested_steps, key=lambda s: s['order']):
                        nested_step_result = {
                            'operation_id': nested_step['operation_id'],
                            'type': nested_step['type'],
                            'order': nested_step['order'],
                            'success': False,
                            'error': None
                        }
                        
                        success, error = _execute_single_step(nested_step, nested_current_path)
                        nested_step_result['success'] = success
                        nested_step_result['error'] = error
                        
                        nested_result['steps'].append(nested_step_result)
                        
                        if not success:
                            nested_result['success'] = False
                            nested_result['error'] = f"Nested step {nested_step['order']} failed: {error}"
                            logger.warning(f"Nested plan failed for {nested_source}: {error}")
                            break
                        
                        if nested_step['type'] in ['move', 'rename', 'copy']:
                            nested_current_path = nested_step['target_path']
                    
                    plan_result['nested_results'].append(nested_result)
            
            plan_results.append(plan_result)
            
            if plan_result['success']:
                successful_files += 1
            else:
                failed_files += 1
        
        # Auto-capture destinations from successful operations
        new_destinations = []
        dest_manager = _get_destination_manager()
        if dest_manager and successful_files > 0:
            try:
                # Build operations list for auto-capture
                successful_ops = []
                for plan_result in plan_results:
                    if plan_result['success']:
                        for step_result in plan_result['steps']:
                            if step_result['success'] and step_result['type'] in ['move', 'copy']:
                                # Find the step details from original plan
                                for plan in file_plans:
                                    if plan['source'] == plan_result['source']:
                                        for step in plan['steps']:
                                            if step['operation_id'] == step_result['operation_id']:
                                                successful_ops.append({
                                                    'type': step['type'],
                                                    'dest': step['target_path']
                                                })
                                                break
                
                if successful_ops:
                    captured = dest_manager.auto_capture_destinations(
                        user_id, successful_ops, client_id
                    )
                    
                    for dest in captured:
                        dest_manager.update_usage(dest.id, file_count=1, operation_type='move')
                    
                    new_destinations = [
                        {
                            'path': dest.path,
                            'category': dest.category,
                            'id': dest.id
                        }
                        for dest in captured
                    ]
                    
                    if new_destinations:
                        logger.info(f"Auto-captured {len(new_destinations)} new destination(s)")
            
            except Exception as capture_error:
                logger.warning(f"Could not auto-capture destinations: {capture_error}")
        
        response = {
            'success': True,
            'analysis_id': analysis_id,
            'plan_results': plan_results,
            'summary': {
                'total_files': len(file_plans),
                'successful_files': successful_files,
                'failed_files': failed_files
            }
        }
        
        if new_destinations:
            response['new_destinations_captured'] = new_destinations
        
        return jsonify(response)
    
    def _execute_legacy_operations(data, analysis_id, operation_ids, web_server):
        """Execute operations using legacy format (backward compatibility)"""
        from datetime import datetime
        
        user_id = data.get('user_id', 'dev_user')
        client_id = data.get('client_id', 'default_client')
        
        conn = web_server._get_file_organizer_db_connection()
        
        try:
            results = []
            for op_id in operation_ids:
                # Get operation details
                cursor = conn.execute("""
                    SELECT operation_type, source_path, destination_path
                    FROM analysis_operations
                    WHERE operation_id = ? AND analysis_id = ?
                """, (op_id, analysis_id))
                
                row = cursor.fetchone()
                if not row:
                    results.append({'operation_id': op_id, 'success': False, 'error': 'Operation not found'})
                    continue
                
                op_type, source, dest = row
                
                # Create a step object for execution
                step = {
                    'type': op_type,
                    'target_path': dest
                }
                
                success, error = _execute_single_step(step, source)
                
                if success:
                    # Update operation status
                    conn.execute("""
                        UPDATE analysis_operations
                        SET operation_status = 'applied', applied_at = ?
                        WHERE operation_id = ?
                    """, (datetime.now().isoformat(), op_id))
                    
                    results.append({'operation_id': op_id, 'success': True})
                else:
                    results.append({'operation_id': op_id, 'success': False, 'error': error})
            
            conn.commit()
            
            # Auto-capture destinations from successful operations
            new_destinations = []
            dest_manager = _get_destination_manager()
            if dest_manager:
                try:
                    # Build operations list for auto-capture
                    successful_ops = []
                    for result in results:
                        if result.get('success'):
                            op_id = result['operation_id']
                            cursor = conn.execute("""
                                SELECT operation_type, destination_path
                                FROM analysis_operations
                                WHERE operation_id = ?
                            """, (op_id,))
                            row = cursor.fetchone()
                            if row and row[1]:
                                successful_ops.append({
                                    'type': row[0],
                                    'dest': row[1]
                                })
                    
                    if successful_ops:
                        captured = dest_manager.auto_capture_destinations(
                            user_id, successful_ops, client_id
                        )
                        
                        for dest in captured:
                            dest_manager.update_usage(dest.id, file_count=1, operation_type='move')
                        
                        new_destinations = [
                            {
                                'path': dest.path,
                                'category': dest.category,
                                'id': dest.id
                            }
                            for dest in captured
                        ]
                        
                        if new_destinations:
                            logger.info(f"Auto-captured {len(new_destinations)} new destination(s)")
                
                except Exception as capture_error:
                    logger.warning(f"Could not auto-capture destinations: {capture_error}")
            
            response = {'success': True, 'results': results}
            if new_destinations:
                response['new_destinations_captured'] = new_destinations
            
            return jsonify(response)
            
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()
    
    def _build_file_plan(file_path, file_result, src_path, dest_root, analysis_id, user_id=None, client_id=None):
        """
        Build a multi-step file plan for a single file.
        Supports nested operations for archives (extract + organize contents).
        
        Returns a dict with:
        - source: absolute source path
        - steps: ordered list of operations (move, rename, tag, etc.)
        - nested_plans: optional list of plans for extracted files
        """
        import uuid
        
        f = Path(file_path)
        steps = []
        nested_plans = []
        
        # Get AI suggested action and folder
        action = file_result.get('action', 'move') if file_result else 'move'
        suggested_folder = file_result.get('suggested_folder') if file_result else None
        confidence = file_result.get('confidence', 0.5) if file_result else 0.0
        extracted_files = file_result.get('extracted_files', {}) if file_result else {}
        
        # Fallback to Uncategorized if AI didn't return a folder
        if not suggested_folder:
            suggested_folder = 'Uncategorized'
        
        # Determine if this is a fallback plan
        is_fallback = not file_result or confidence < 0.3
        
        # AI returns the folder/path - use it as-is
        # If AI returns an absolute path, use it directly
        # If AI returns a relative folder name, append to dest_root
        if Path(suggested_folder).is_absolute():
            dest_base = Path(suggested_folder)
        else:
            dest_base = dest_root / suggested_folder
        
        # Preserve relative subfolder structure for nested files
        try:
            relative_path = f.relative_to(src_path)
            if len(relative_path.parts) > 1:
                # File is in a subfolder - preserve the structure
                dest_path = dest_base / relative_path
            else:
                # File is at root level
                dest_path = dest_base / f.name
        except ValueError:
            # File is not relative to source path
            dest_path = dest_base / f.name
        
        # Step 1: Primary action (move/delete/unpack)
        if action == 'delete':
            steps.append({
                'operation_id': f"{analysis_id}_op_{uuid.uuid4().hex[:8]}",
                'type': 'delete',
                'target_path': None,
                'reason': file_result.get('reason', 'Redundant archive - content already extracted'),
                'order': 1,
                'metadata': {
                    'confidence': str(confidence),
                    'is_fallback': is_fallback
                }
            })
        elif action == 'unpack':
            unpack_dest = dest_root / 'ToReview' / f.stem
            steps.append({
                'operation_id': f"{analysis_id}_op_{uuid.uuid4().hex[:8]}",
                'type': 'unpack',
                'target_path': str(unpack_dest),
                'reason': file_result.get('reason', 'Archive content unknown - unpack to analyze'),
                'order': 1,
                'metadata': {
                    'confidence': str(confidence),
                    'is_fallback': is_fallback
                }
            })
        else:
            # Regular move operation
            reason = file_result.get('reason', f'Matches {suggested_folder} category') if file_result else 'No AI analysis - defaulting to Uncategorized'
            if is_fallback:
                reason = f'Low confidence categorization - {reason}'
            
            steps.append({
                'operation_id': f"{analysis_id}_op_{uuid.uuid4().hex[:8]}",
                'type': 'move',
                'target_path': str(dest_path),
                'reason': reason,
                'order': 1,
                'metadata': {
                    'confidence': str(confidence),
                    'suggested_folder': suggested_folder,
                    'is_fallback': is_fallback
                }
            })
            
        # Handle nested operations for extracted files
        if action == 'unpack' and extracted_files:
            # AI provided operations for files inside the archive
            unpack_dest = dest_root / 'ToReview' / f.stem if action == 'unpack' else dest_base
            
            for extracted_filename, extracted_op in extracted_files.items():
                # Build full path for extracted file
                extracted_path = unpack_dest / extracted_filename
                
                # Get operation details
                extracted_action = extracted_op.get('action', 'move')
                extracted_folder = extracted_op.get('suggested_folder', 'Uncategorized')
                new_name = extracted_op.get('new_name')
                reason = extracted_op.get('reason', '')
                
                # Build steps for this extracted file
                extracted_steps = []
                step_order = 1
                current_name = extracted_filename
                
                # Step 1: Rename if needed
                if new_name and new_name != extracted_filename:
                    rename_path = unpack_dest / new_name
                    extracted_steps.append({
                        'operation_id': f"{analysis_id}_nested_{uuid.uuid4().hex[:8]}",
                        'type': 'rename',
                        'target_path': str(rename_path),
                        'reason': reason or f'Clean filename: {extracted_filename} → {new_name}',
                        'order': step_order,
                        'metadata': {}
                    })
                    step_order += 1
                    current_name = new_name
                
                # Step 2: Move or Delete
                if extracted_action == 'delete':
                    extracted_steps.append({
                        'operation_id': f"{analysis_id}_nested_{uuid.uuid4().hex[:8]}",
                        'type': 'delete',
                        'target_path': None,
                        'reason': reason or 'Garbage file',
                        'order': step_order,
                        'metadata': {}
                    })
                elif extracted_action == 'move':
                    # Determine destination
                    if Path(extracted_folder).is_absolute():
                        final_dest = Path(extracted_folder) / current_name
                    else:
                        final_dest = dest_root / extracted_folder / current_name
                    
                    extracted_steps.append({
                        'operation_id': f"{analysis_id}_nested_{uuid.uuid4().hex[:8]}",
                        'type': 'move',
                        'target_path': str(final_dest),
                        'reason': reason or f'Organize to {extracted_folder}',
                        'order': step_order,
                        'metadata': {'suggested_folder': extracted_folder}
                    })
                
                # Add nested plan for this extracted file
                if extracted_steps:
                    nested_plans.append({
                        'source': str(extracted_path),
                        'steps': extracted_steps,
                        'parent_archive': file_path
                    })
        
        plan = {
            'source': file_path,
            'steps': steps
        }
        
        # Add nested plans if any
        if nested_plans:
            plan['nested_plans'] = nested_plans
        
        return plan
    
    def _get_ai_context_builder():
        """Get AIContextBuilder instance"""
        try:
            file_organizer_app = web_server.app_manager.get_module('file_organizer')
            if file_organizer_app and hasattr(file_organizer_app, 'path_memory_manager'):
                path_mgr = file_organizer_app.path_memory_manager
                if hasattr(path_mgr, '_destination_manager') and hasattr(path_mgr, '_drive_manager'):
                    from file_organizer.ai_context_builder import AIContextBuilder
                    return AIContextBuilder(path_mgr._destination_manager, path_mgr._drive_manager)
        except Exception as e:
            logger.warning(f"Could not get AIContextBuilder: {e}")
        return None

    def _get_destination_manager():
        """Get DestinationMemoryManager instance"""
        try:
            file_organizer_app = web_server.app_manager.get_module('file_organizer')
            if file_organizer_app and hasattr(file_organizer_app, 'path_memory_manager'):
                path_mgr = file_organizer_app.path_memory_manager
                if hasattr(path_mgr, '_destination_manager'):
                    return path_mgr._destination_manager
        except Exception as e:
            logger.warning(f"Could not get DestinationMemoryManager: {e}")
        return None

    @app.route('/api/file-organizer/organize', methods=['POST'])
    def fo_organize():
        try:
            data = request.get_json(force=True, silent=True) or {}
            
            # Parse and validate request using Pydantic model
            from file_organizer.request_models import OrganizeRequest
            try:
                org_request = OrganizeRequest(**data)
            except Exception as validation_error:
                logger.warning(f"Request validation failed: {validation_error}")
                # Fall back to manual parsing for backward compatibility
                org_request = None
            
            if org_request:
                source_folder = org_request.source_path
                destination_folder = org_request.destination_path
                organization_style = org_request.organization_style
                user_id = org_request.user_id
                client_id = org_request.client_id
                granularity = data.get('granularity', 1)  # Default to broad organization
                
                # Get unified file list with metadata
                files_with_meta = org_request.get_file_list()
                provided_file_paths = [f['path'] for f in files_with_meta]
                files_metadata = {f['path']: f['metadata'] for f in files_with_meta if f['metadata']}
            else:
                # Legacy parsing
                source_folder = data.get('source_path')
                destination_folder = data.get('destination_path')
                organization_style = data.get('organization_style', 'by_type')
                user_id = data.get('user_id', 'dev_user')
                client_id = data.get('client_id', 'default_client')
                granularity = data.get('granularity', 1)  # Default to broad organization
                
                # Frontend can optionally provide explicit file list (including nested files)
                provided_file_paths = data.get('file_paths', [])
                files_metadata = {}

            if not source_folder:
                return jsonify({'success': False, 'error': 'source_path required'}), 400
            if not destination_folder:
                return jsonify({'success': False, 'error': 'destination_path required'}), 400

            # Get the File Organizer App instance
            app_manager = web_server.components.get('app_manager')
            if not app_manager:
                return jsonify({'success': False, 'error': 'app_manager_unavailable'}), 500
            
            # For now, bypass the module system and work directly with the database
            # This is a temporary solution until we fix the async module startup
            pass

            # until the AI generator is fully re-integrated.
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            
            src_path = Path(source_folder).expanduser()
            dest_root = Path(destination_folder).expanduser()
            if not src_path.exists() or not src_path.is_dir():
                return jsonify({'success': False, 'error': f'source_folder not found: {source_folder}'}), 400

            # Use provided file paths if available (includes nested files from frontend)
            # Otherwise, scan only root-level files (legacy behavior)
            if provided_file_paths:
                logger.info(f"Using {len(provided_file_paths)} file paths provided by frontend")
                file_paths = provided_file_paths
                files = [Path(fp) for fp in file_paths if Path(fp).exists() and Path(fp).is_file()]
            else:
                logger.info(f"Scanning root-level files in {source_folder}")
                files = [p for p in src_path.iterdir() if p.is_file()]
                file_paths = [str(f) for f in files]
            
            logger.info(f"Processing {len(file_paths)} files for organization")
            
            # Get existing folders in destination for context-aware organization
            existing_folders = []
            if dest_root.exists():
                existing_folders = [d.name for d in dest_root.iterdir() if d.is_dir()]
            
            # Build AI context with known destinations and drives
            ai_context_text = None
            context_builder = _get_ai_context_builder()
            if context_builder:
                try:
                    context = context_builder.build_context(user_id, client_id)
                    
                    # If no destinations exist, add source folder as the only destination
                    if not context.get('known_destinations'):
                        logger.info("No saved destinations - using source folder as destination")
                        context['known_destinations'] = [{
                            'category': 'Source',
                            'paths': [{
                                'path': str(src_path),
                                'drive_type': 'local',
                                'drive_label': None,
                                'available_space_gb': None,
                                'is_available': True,
                                'usage_count': 0,
                                'last_used': None,
                                'cloud_provider': None
                            }]
                        }]
                    
                    ai_context_text = context_builder.format_for_ai_prompt(context)
                    logger.info(f"Built AI context: {context_builder.build_context_summary(user_id, client_id)}")
                except Exception as e:
                    logger.warning(f"Could not build AI context: {e}")
            
            # Use shared batch analysis method (SINGLE SOURCE OF TRUTH)
            batch_result = web_server._batch_analyze_files(
                file_paths, 
                use_ai=True, 
                existing_folders=existing_folders,
                ai_context=ai_context_text,
                files_metadata=files_metadata if org_request else None,
                source_path=source_folder,
                granularity=granularity
            )
            
            if not batch_result.get('success'):
                error_response = {
                    'success': False,
                    'error': f"Batch analysis failed: {batch_result.get('error')}"
                }
                
                # Add error details if available
                if 'error_details' in batch_result:
                    error_response['error_details'] = batch_result['error_details']
                
                return jsonify(error_response), 503
            
            # Create analysis ID for this session
            import uuid
            analysis_id = str(uuid.uuid4())
            
            operations = []  # Legacy format (backward compatibility)
            file_plans = []  # New multi-step format
            errors = []
            results = batch_result.get('results', {})
            
            logger.info(f"Batch analysis returned {len(results)} results for {len(files)} files")
            
            for f in files:
                file_path = str(f)
                file_result = results.get(file_path)
                
                # Build file plan (new multi-step format)
                file_plan = _build_file_plan(file_path, file_result, src_path, dest_root, analysis_id)
                file_plans.append(file_plan)
                
                # Build legacy operation (backward compatibility)
                if not file_result:
                    error_msg = f"No analysis result for {f.name}"
                    logger.warning(error_msg)
                    logger.warning(f"Fallback plan created for: {file_path}")
                    
                    # FALLBACK: Create an "Uncategorized" operation
                    dest_path = dest_root / 'Uncategorized' / f.name
                    operations.append({
                        'type': 'move',
                        'source': file_path,
                        'destination': str(dest_path),
                        'reason_hint': 'No AI analysis result - defaulting to Uncategorized',
                        'operation_id': file_plan['steps'][0]['operation_id']
                    })
                    
                    errors.append({
                        'file': file_path,
                        'error': 'No analysis result returned - using fallback'
                    })
                    continue
                
                # Get AI suggested action (move/delete/unpack)
                action = file_result.get('action', 'move')
                suggested_folder = file_result.get('suggested_folder', 'Other')
                
                # Extract first step from plan for legacy format
                first_step = file_plan['steps'][0]
                
                if action == 'delete':
                    operations.append({
                        'type': 'delete',
                        'source': file_path,
                        'destination': None,
                        'reason_hint': first_step['reason'],
                        'operation_id': first_step['operation_id']
                    })
                elif action == 'unpack':
                    operations.append({
                        'type': 'unpack',
                        'source': file_path,
                        'destination': first_step['target_path'],
                        'reason_hint': first_step['reason'],
                        'operation_id': first_step['operation_id']
                    })
                else:
                    operations.append({
                        'type': 'move',
                        'source': file_path,
                        'destination': first_step['target_path'],
                        'reason_hint': first_step['reason'],
                        'operation_id': first_step['operation_id']
                    })
            
            # Validate: counts should match
            logger.info(f"Generated {len(operations)} operations and {len(file_plans)} file plans for {len(files)} input files")
            
            if len(operations) != len(files):
                logger.warning(f"OPERATIONS MISMATCH: Expected {len(files)} operations but got {len(operations)}")
                logger.warning(f"Missing files: {set(str(f) for f in files) - set(op['source'] for op in operations)}")
            
            if len(file_plans) != len(files):
                logger.error(f"FILE PLANS MISMATCH: Expected {len(files)} file plans but got {len(file_plans)}")
                logger.error(f"Missing files: {set(str(f) for f in files) - set(plan['source'] for plan in file_plans)}")
            
            # Count fallback plans
            fallback_count = sum(1 for plan in file_plans if plan['steps'][0]['metadata'].get('is_fallback'))
            if fallback_count > 0:
                logger.warning(f"Generated {fallback_count} fallback 'Uncategorized' plans")
            
            # If ALL files failed, return error
            if not operations and errors:
                return jsonify({
                    'success': False, 
                    'error': 'All files failed to analyze',
                    'details': errors
                }), 503

            # Create a persistent analysis session directly in the database
            import json
            from datetime import datetime
            
            now = datetime.now().isoformat()
            
            # Connect to the database using shared method
            conn = web_server._get_file_organizer_db_connection()
            
            try:
                # Insert analysis session
                conn.execute("""
                    INSERT INTO analysis_sessions 
                    (analysis_id, user_id, source_path, destination_path, organization_style, 
                     file_count, created_at, updated_at, status, metadata)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    analysis_id,
                    user_id,
                    source_folder,
                    destination_folder,
                    organization_style,
                    len(operations),
                    now,
                    now,
                    'pending',
                    json.dumps({
                        'total_files': len(files),
                        'successful_operations': len(operations),
                        'failed_files': len(errors),
                        'file_plans_count': len(file_plans),
                        'fallback_plans_count': fallback_count
                    })
                ))
                
                # Insert operations
                for idx, op in enumerate(operations):
                    operation_id = f"{analysis_id}_op_{idx}"
                    conn.execute("""
                        INSERT INTO analysis_operations
                        (operation_id, analysis_id, operation_type, source_path, destination_path,
                         file_name, operation_status, metadata)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        operation_id,
                        analysis_id,
                        op['type'],
                        op['source'],
                        op['destination'],
                        Path(op['source']).name,
                        'pending',
                        json.dumps({})
                    ))
                    # Add operation_id to response
                    op['operation_id'] = operation_id
                    op['status'] = 'pending'
                
                conn.commit()
                
                # Extract unique destination folders and suggest colors
                suggested_destinations = {}
                dest_manager = _get_destination_manager()
                
                if dest_manager:
                    # Get existing colors to avoid duplicates
                    existing_destinations = dest_manager.get_destinations(user_id)
                    existing_colors = [d.color for d in existing_destinations if d.color]
                    
                    # Extract unique destination folders from operations
                    unique_dest_folders = set()
                    for op in operations:
                        if op.get('destination'):
                            dest_path = Path(op['destination'])
                            # Get the immediate subfolder under dest_root
                            try:
                                rel_path = dest_path.relative_to(dest_root)
                                if rel_path.parts:
                                    folder_name = rel_path.parts[0]
                                    unique_dest_folders.add(folder_name)
                            except ValueError:
                                pass
                    
                    # Suggest colors for new destinations
                    from file_organizer.color_palette import assign_color_from_palette
                    for folder_name in unique_dest_folders:
                        # Check if this destination already exists
                        existing_dest = next((d for d in existing_destinations if folder_name.lower() in d.category.lower()), None)
                        if existing_dest and existing_dest.color:
                            # Use existing color
                            suggested_destinations[folder_name] = {
                                'path': str(dest_root / folder_name),
                                'category': folder_name,
                                'color': existing_dest.color,
                                'is_existing': True
                            }
                        else:
                            # Suggest new color
                            suggested_color = assign_color_from_palette(existing_colors)
                            existing_colors.append(suggested_color)  # Track for next iteration
                            suggested_destinations[folder_name] = {
                                'path': str(dest_root / folder_name),
                                'category': folder_name,
                                'color': suggested_color,
                                'is_existing': False
                            }
                
                response = {
                    'success': True,
                    'analysis_id': analysis_id,
                    'operations': operations,  # Legacy format (backward compatibility)
                    'file_plans': file_plans,  # New multi-step format
                    'suggested_destinations': suggested_destinations,  # NEW: Suggested colors for destinations
                    'counts': {
                        'files_received': len(files),
                        'operations_generated': len(operations),
                        'file_plans_generated': len(file_plans),
                        'fallback_plans': fallback_count
                    }
                }
                
                # Include errors if any (partial success)
                if errors:
                    response['errors'] = errors
                
                return jsonify(response)
                
            except Exception as db_error:
                conn.rollback()
                logger.error(f"Database error: {db_error}", exc_info=True)
                return jsonify({'success': False, 'error': f'Database error: {str(db_error)}'}), 500
            finally:
                conn.close()
                
        except Exception as e:
            logger.error(f"/organize error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/execute', methods=['POST'])
    def fo_execute_ops():
        """
        Execute approved file operations.
        
        Supports two modes:
        1. Legacy: operation_ids array (backward compatibility)
        2. New: file_plans array with multi-step execution
        """
        try:
            data = request.get_json(force=True, silent=True) or {}
            analysis_id = data.get('analysis_id')
            operation_ids = data.get('operation_ids', [])
            file_plans = data.get('file_plans', [])
            
            if not analysis_id:
                return jsonify({'success': False, 'error': 'analysis_id required'}), 400
            
            # Determine execution mode
            use_file_plans = len(file_plans) > 0
            
            if use_file_plans:
                logger.info(f"Executing {len(file_plans)} file plans (new multi-step mode)")
                return _execute_file_plans(data, analysis_id, file_plans, web_server)
            else:
                logger.info(f"Executing {len(operation_ids)} operations (legacy mode)")
                return _execute_legacy_operations(data, analysis_id, operation_ids, web_server)
                
        except Exception as e:
            logger.error(f"/execute error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/file-organizer/add-granularity', methods=['POST'])
    def fo_add_granularity():
        """
        Add ONE level of granularity to files in a specific folder.
        AI decides which files should go into subfolders and which should stay.
        
        Supports two modes:
        1. Existing folder: Reads files from the folder on disk
        2. Proposed folder: Uses file_paths array for not-yet-moved files
        """
        try:
            data = request.get_json(force=True, silent=True) or {}
            folder_path = data.get('folder_path')
            file_paths = data.get('file_paths')  # Optional: for proposed folders
            analysis_id = data.get('analysis_id')  # Optional: to track this as part of an analysis session
            
            if not folder_path:
                return jsonify({'success': False, 'error': 'folder_path is required'}), 400
            
            import os
            
            folder = Path(folder_path)
            items = []
            
            # MODE 1: Proposed folder with explicit file_paths (files haven't been moved yet)
            if file_paths:
                logger.info(f"Add granularity in PROPOSED mode: {len(file_paths)} files provided")
                for file_path in file_paths:
                    file_obj = Path(file_path)
                    if file_obj.exists():
                        items.append({
                            'path': str(file_obj),
                            'name': file_obj.name,
                            'is_file': file_obj.is_file(),
                            'is_dir': file_obj.is_dir(),
                            'extension': file_obj.suffix.lower() if file_obj.is_file() else None
                        })
            
            # MODE 2: Existing folder (read files from disk)
            else:
                if not folder.exists() or not folder.is_dir():
                    return jsonify({'success': False, 'error': f'Folder does not exist: {folder_path}'}), 404
                
                logger.info(f"Add granularity in EXISTING mode: analyzing folder {folder_path}")
                # Get all items (files and subfolders) in this folder
                for item in folder.iterdir():
                    items.append({
                        'path': str(item),
                        'name': item.name,
                        'is_file': item.is_file(),
                        'is_dir': item.is_dir(),
                        'extension': item.suffix.lower() if item.is_file() else None
                    })
            
            if not items:
                return jsonify({
                    'success': True,
                    'operations': [],
                    'message': 'No files to analyze'
                })
            
            # Call AI to add granularity
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            shared_services = web_server.components.get('shared_services')
            analyzer = AIContentAnalyzer(shared_services=shared_services)
            
            result = analyzer.add_granularity(folder_path, items)
            
            if not result.get('success'):
                return jsonify(result), 503
            
            # Convert AI suggestions into FileOperation format
            operations = []
            for item_path, suggestion in result.get('suggestions', {}).items():
                subfolder = suggestion.get('subfolder')
                
                # If subfolder is None or empty, skip (file stays in current location)
                if not subfolder:
                    continue
                
                # Create operation
                item_name = Path(item_path).name
                new_destination = str(folder / subfolder / item_name)
                
                operations.append({
                    'type': 'move',
                    'source': item_path,
                    'destination': new_destination,
                    # reason will be generated on-demand
                })
            
            return jsonify({
                'success': True,
                'operations': operations,
                'folder': folder_path,
                'items_analyzed': len(items),
                'items_to_organize': len(operations)
            })
            
        except Exception as e:
            logger.error(f"/add-granularity error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500
    
    @app.route('/api/file-organizer/estimate-tokens', methods=['POST'])
    def fo_estimate_tokens():
        """
        Estimate token count for a file organization request.
        Frontend sends the SAME request body it would send to /organize,
        and backend simulates the AI call to count exact tokens.
        
        Request body: Same as /organize endpoint
        {
            "source_path": "/path/to/source",
            "destination_path": "/path/to/dest",
            "files_with_metadata": [...],
            "granularity": 1,
            "user_id": "user123",
            "client_id": "client123"
        }
        
        Response:
        {
            "success": true,
            "input_tokens": 5234,
            "estimated_output_tokens": 1500,
            "total_tokens": 6734,
            "estimated_cost_usd": 0.000842,
            "method": "exact",
            "breakdown": {
                "input_method": "exact",
                "output_method": "estimated"
            }
        }
        """
        try:
            from file_organizer.token_counter import TokenCounter
            from file_organizer.ai_content_analyzer import AIContentAnalyzer
            from file_organizer.request_models import OrganizeRequest
            
            data = request.get_json()
            
            # Parse request (same as /organize)
            try:
                org_request = OrganizeRequest(**data)
            except Exception:
                org_request = None
            
            if org_request:
                source_folder = org_request.source_path
                destination_folder = org_request.destination_path
                user_id = org_request.user_id
                client_id = org_request.client_id
                granularity = data.get('granularity', 1)
                
                files_with_meta = org_request.get_file_list()
                provided_file_paths = [f['path'] for f in files_with_meta]
                files_metadata = {f['path']: f['metadata'] for f in files_with_meta if f['metadata']}
            else:
                # Legacy parsing
                source_folder = data.get('source_path')
                destination_folder = data.get('destination_path')
                user_id = data.get('user_id', 'dev_user')
                client_id = data.get('client_id', 'default_client')
                granularity = data.get('granularity', 1)
                provided_file_paths = data.get('file_paths', [])
                files_metadata = {}
            
            if not source_folder or not destination_folder:
                return jsonify({'success': False, 'error': 'source_path and destination_path required'}), 400
            
            # Get file paths
            src_path = Path(source_folder).expanduser()
            if provided_file_paths:
                file_paths = provided_file_paths
            else:
                files = [p for p in src_path.iterdir() if p.is_file()]
                file_paths = [str(f) for f in files]
            
            # Build AI context (same as /organize)
            ai_context_text = None
            context_builder = _get_ai_context_builder()
            if context_builder:
                try:
                    context = context_builder.build_context(user_id, client_id)
                    ai_context_text = context_builder.format_for_ai_prompt(context)
                except Exception as e:
                    logger.warning(f"Could not build AI context: {e}")
            
            # Build the ACTUAL prompt that would be sent to AI
            shared_services = web_server.components.get('shared_services')
            analyzer = AIContentAnalyzer(shared_services=shared_services)
            
            # Call internal method to build prompt (without sending to AI)
            prompt = analyzer._build_prompt_for_batch(
                file_paths,
                existing_folders=[],
                ai_context=ai_context_text,
                files_metadata=files_metadata,
                source_path=source_folder,
                granularity=granularity
            )
            
            # Count input tokens using actual prompt
            counter = TokenCounter(shared_services)
            input_count = counter.count_tokens(prompt)
            
            # Estimate output tokens (indexed format: ~10 tokens per file)
            estimated_output = len(file_paths) * 10
            
            total_tokens = input_count['tokens'] + estimated_output
            
            # Calculate cost (provider auto-detected from shared services)
            cost_info = counter.estimate_cost(
                input_count['tokens'],
                estimated_output
            )
            
            return jsonify({
                'success': True,
                'input_tokens': input_count['tokens'],
                'estimated_output_tokens': estimated_output,
                'total_tokens': total_tokens,
                'estimated_cost_usd': cost_info['total_cost_usd'],
                'method': input_count['method'],
                'breakdown': {
                    'input_method': input_count['method'],
                    'output_method': 'estimated',
                    'file_count': len(file_paths)
                }
            })
            
        except Exception as e:
            logger.error(f"/estimate-tokens error: {e}", exc_info=True)
            return jsonify({'success': False, 'error': str(e)}), 500

# REMOVE OLD DUPLICATE CODE BELOW THIS LINE - IT SHOULD NOT EXIST
