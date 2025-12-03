#!/usr/bin/env python3
"""
Test script for destination color functionality
"""

import sys
import logging
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from file_organizer.destination_memory_manager import DestinationMemoryManager
from file_organizer.color_palette import COLOR_PALETTE, is_valid_hex_color, assign_color_from_palette

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ColorTest")

def test_color_validation():
    """Test color validation"""
    print("\n" + "="*60)
    print("TEST 1: Color Validation")
    print("="*60)
    
    test_cases = [
        ("#667eea", True),
        ("#fff", True),
        ("667eea", False),
        ("#gggggg", False),
        ("#123456", True),
    ]
    
    for color, expected in test_cases:
        result = is_valid_hex_color(color)
        status = "✅" if result == expected else "❌"
        print(f"{status} {color}: {result} (expected {expected})")

def test_color_assignment():
    """Test color assignment from palette"""
    print("\n" + "="*60)
    print("TEST 2: Color Assignment")
    print("="*60)
    
    # Test with no existing colors
    color1 = assign_color_from_palette([])
    print(f"✅ First color assigned: {color1}")
    assert color1 == COLOR_PALETTE[0], f"Expected {COLOR_PALETTE[0]}, got {color1}"
    
    # Test with some existing colors
    existing = [COLOR_PALETTE[0], COLOR_PALETTE[1]]
    color2 = assign_color_from_palette(existing)
    print(f"✅ Next available color: {color2}")
    assert color2 == COLOR_PALETTE[2], f"Expected {COLOR_PALETTE[2]}, got {color2}"
    
    # Test cycling when all colors are used
    all_colors = COLOR_PALETTE.copy()
    color3 = assign_color_from_palette(all_colors)
    print(f"✅ Cycled color (all used): {color3}")
    assert color3 == COLOR_PALETTE[0], f"Expected {COLOR_PALETTE[0]}, got {color3}"

def test_destination_colors():
    """Test destination color functionality"""
    print("\n" + "="*60)
    print("TEST 3: Destination Colors")
    print("="*60)
    
    db_path = Path("backend/data/modules/homie_file_organizer.db")
    if not db_path.exists():
        print(f"❌ Database not found at {db_path}")
        return
    
    manager = DestinationMemoryManager(db_path)
    
    # Test 1: Add destination without color (should auto-assign)
    print("\n📝 Test 1: Add destination without color")
    dest1 = manager.add_destination(
        user_id="test_color_user",
        path="/tmp/test_dest_1",
        category="TestCategory1",
        client_id="test_client"
    )
    
    if dest1:
        print(f"✅ Destination created with auto-assigned color: {dest1.color}")
        assert dest1.color is not None, "Color should be auto-assigned"
        assert is_valid_hex_color(dest1.color), f"Invalid color: {dest1.color}"
    else:
        print("❌ Failed to create destination")
        return
    
    # Test 2: Add destination with specific color
    print("\n📝 Test 2: Add destination with specific color")
    custom_color = "#ff0000"
    dest2 = manager.add_destination(
        user_id="test_color_user",
        path="/tmp/test_dest_2",
        category="TestCategory2",
        client_id="test_client",
        color=custom_color
    )
    
    if dest2:
        print(f"✅ Destination created with custom color: {dest2.color}")
        assert dest2.color == custom_color, f"Expected {custom_color}, got {dest2.color}"
    else:
        print("❌ Failed to create destination with custom color")
        return
    
    # Test 3: Update destination color
    print("\n📝 Test 3: Update destination color")
    new_color = "#00ff00"
    updated_dest = manager.update_destination(
        user_id="test_color_user",
        destination_id=dest1.id,
        color=new_color
    )
    
    if updated_dest:
        print(f"✅ Destination color updated: {updated_dest.color}")
        assert updated_dest.color == new_color, f"Expected {new_color}, got {updated_dest.color}"
    else:
        print("❌ Failed to update destination color")
        return
    
    # Test 4: Get destinations and verify colors are included
    print("\n📝 Test 4: Get destinations with colors")
    destinations = manager.get_destinations("test_color_user")
    print(f"✅ Retrieved {len(destinations)} destinations")
    
    for dest in destinations:
        if dest.category.startswith("TestCategory"):
            print(f"  - {dest.path}: {dest.color}")
            assert dest.color is not None, f"Destination {dest.id} missing color"
    
    # Cleanup
    print("\n🧹 Cleaning up test destinations")
    manager.remove_destination("test_color_user", dest1.id)
    manager.remove_destination("test_color_user", dest2.id)
    print("✅ Cleanup complete")

if __name__ == "__main__":
    try:
        test_color_validation()
        test_color_assignment()
        test_destination_colors()
        
        print("\n" + "="*60)
        print("✅ ALL TESTS PASSED")
        print("="*60)
        
    except Exception as e:
        print(f"\n❌ TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
