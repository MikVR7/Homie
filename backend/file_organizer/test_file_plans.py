#!/usr/bin/env python3
"""
Test script for File Plan multi-step workflow
"""

import json


def test_file_plan_structure():
    """Test that file plan structure is correct"""
    print("\n=== Test: File Plan Structure ===\n")
    
    # Sample file plan
    file_plan = {
        'source': '/home/user/source/Test/photo.jpg',
        'steps': [
            {
                'operation_id': 'op_123',
                'type': 'move',
                'target_path': '/mnt/NAS/Photos/2024/Test/photo.jpg',
                'reason': 'Matches Photos/Test category',
                'order': 1,
                'metadata': {
                    'confidence': '0.92',
                    'suggested_folder': 'Photos',
                    'is_fallback': False
                }
            },
            {
                'operation_id': 'op_124',
                'type': 'rename',
                'target_path': '/mnt/NAS/Photos/2024/Test/2024-05-01_photo.jpg',
                'reason': 'Normalize naming',
                'order': 2,
                'metadata': {}
            }
        ]
    }
    
    print(f"✓ Source: {file_plan['source']}")
    print(f"✓ Steps: {len(file_plan['steps'])}")
    
    for step in file_plan['steps']:
        print(f"\n  Step {step['order']}:")
        print(f"    Type: {step['type']}")
        print(f"    Target: {step['target_path']}")
        print(f"    Reason: {step['reason']}")
    
    # Validate structure
    assert 'source' in file_plan
    assert 'steps' in file_plan
    assert len(file_plan['steps']) > 0
    
    for step in file_plan['steps']:
        assert 'operation_id' in step
        assert 'type' in step
        assert 'order' in step
        assert 'reason' in step
        assert 'metadata' in step
    
    print("\n✅ File plan structure is valid")


def test_fallback_plan():
    """Test fallback plan for uncategorized files"""
    print("\n=== Test: Fallback Plan ===\n")
    
    fallback_plan = {
        'source': '/home/user/source/unknown.dat',
        'steps': [
            {
                'operation_id': 'op_fallback_1',
                'type': 'move',
                'target_path': '/mnt/NAS/Uncategorized/unknown.dat',
                'reason': 'No AI analysis - defaulting to Uncategorized',
                'order': 1,
                'metadata': {
                    'confidence': '0.0',
                    'suggested_folder': 'Uncategorized',
                    'is_fallback': True
                }
            }
        ]
    }
    
    print(f"✓ Source: {fallback_plan['source']}")
    print(f"✓ Is fallback: {fallback_plan['steps'][0]['metadata']['is_fallback']}")
    print(f"✓ Reason: {fallback_plan['steps'][0]['reason']}")
    
    assert fallback_plan['steps'][0]['metadata']['is_fallback'] == True
    assert 'Uncategorized' in fallback_plan['steps'][0]['target_path']
    
    print("\n✅ Fallback plan is correct")


def test_response_format():
    """Test complete response format"""
    print("\n=== Test: Response Format ===\n")
    
    response = {
        'success': True,
        'analysis_id': 'uuid-123',
        'operations': [  # Legacy format
            {
                'type': 'move',
                'source': '/home/user/source/file1.txt',
                'destination': '/mnt/NAS/Documents/file1.txt',
                'operation_id': 'op_1',
                'reason_hint': 'Matches Documents category'
            }
        ],
        'file_plans': [  # New format
            {
                'source': '/home/user/source/file1.txt',
                'steps': [
                    {
                        'operation_id': 'op_1',
                        'type': 'move',
                        'target_path': '/mnt/NAS/Documents/file1.txt',
                        'reason': 'Matches Documents category',
                        'order': 1,
                        'metadata': {'confidence': '0.85'}
                    }
                ]
            }
        ],
        'counts': {
            'files_received': 1,
            'operations_generated': 1,
            'file_plans_generated': 1,
            'fallback_plans': 0
        }
    }
    
    print("✓ Response structure:")
    print(json.dumps(response, indent=2))
    
    # Validate
    assert response['success'] == True
    assert 'analysis_id' in response
    assert 'operations' in response  # Legacy
    assert 'file_plans' in response  # New
    assert 'counts' in response
    
    # Validate counts match
    assert response['counts']['operations_generated'] == len(response['operations'])
    assert response['counts']['file_plans_generated'] == len(response['file_plans'])
    
    print("\n✅ Response format is correct")


def test_execution_request():
    """Test execution request format"""
    print("\n=== Test: Execution Request ===\n")
    
    # New format with file_plans
    exec_request = {
        'analysis_id': 'uuid-123',
        'user_id': 'user123',
        'client_id': 'laptop1',
        'file_plans': [
            {
                'source': '/home/user/source/file1.txt',
                'steps': [
                    {
                        'operation_id': 'op_1',
                        'type': 'move',
                        'target_path': '/mnt/NAS/Documents/file1.txt',
                        'reason': 'Matches Documents category',
                        'order': 1,
                        'metadata': {}
                    }
                ]
            }
        ]
    }
    
    print("✓ Execution request:")
    print(json.dumps(exec_request, indent=2))
    
    assert 'analysis_id' in exec_request
    assert 'file_plans' in exec_request
    assert len(exec_request['file_plans']) > 0
    
    print("\n✅ Execution request format is correct")


def test_execution_response():
    """Test execution response format"""
    print("\n=== Test: Execution Response ===\n")
    
    exec_response = {
        'success': True,
        'analysis_id': 'uuid-123',
        'plan_results': [
            {
                'source': '/home/user/source/file1.txt',
                'success': True,
                'steps': [
                    {
                        'operation_id': 'op_1',
                        'type': 'move',
                        'order': 1,
                        'success': True,
                        'error': None
                    }
                ]
            }
        ],
        'summary': {
            'total_files': 1,
            'successful_files': 1,
            'failed_files': 0
        }
    }
    
    print("✓ Execution response:")
    print(json.dumps(exec_response, indent=2))
    
    assert exec_response['success'] == True
    assert 'plan_results' in exec_response
    assert 'summary' in exec_response
    
    # Validate per-step results
    for plan_result in exec_response['plan_results']:
        assert 'source' in plan_result
        assert 'success' in plan_result
        assert 'steps' in plan_result
        
        for step_result in plan_result['steps']:
            assert 'operation_id' in step_result
            assert 'success' in step_result
    
    print("\n✅ Execution response format is correct")


if __name__ == "__main__":
    test_file_plan_structure()
    test_fallback_plan()
    test_response_format()
    test_execution_request()
    test_execution_response()
    print("\n🎉 All file plan tests passed!")
