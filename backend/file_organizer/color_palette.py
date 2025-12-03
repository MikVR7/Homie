#!/usr/bin/env python3
"""
Color Palette for Destination Visual Identification

Provides a predefined palette of 20 distinct, accessible colors for
assigning to destination folders.
"""

import re
from typing import List, Optional

# Predefined color palette - 20 distinct, accessible colors
COLOR_PALETTE = [
    "#667eea",  # Purple
    "#f093fb",  # Pink
    "#4facfe",  # Blue
    "#00f2fe",  # Cyan
    "#43e97b",  # Green
    "#fa709a",  # Rose
    "#fee140",  # Yellow
    "#30cfd0",  # Teal
    "#a8edea",  # Aqua
    "#fed6e3",  # Light Pink
    "#ff9a9e",  # Coral
    "#fecfef",  # Lavender
    "#fad0c4",  # Peach
    "#ffd1ff",  # Light Purple
    "#a1c4fd",  # Light Blue
    "#ffecd2",  # Cream
    "#fcb69f",  # Orange
    "#ff8a80",  # Red
    "#b2fefa",  # Mint
    "#81f5ff",  # Sky Blue
]


def is_valid_hex_color(color: str) -> bool:
    """
    Validate if a string is a valid hex color code
    
    Args:
        color: Color string to validate
        
    Returns:
        True if valid hex color, False otherwise
        
    Examples:
        >>> is_valid_hex_color("#667eea")
        True
        >>> is_valid_hex_color("#fff")
        True
        >>> is_valid_hex_color("667eea")
        False
        >>> is_valid_hex_color("#gggggg")
        False
    """
    if not color:
        return False
    
    # Match #RGB or #RRGGBB format
    pattern = r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$'
    return bool(re.match(pattern, color))


def normalize_hex_color(color: str) -> Optional[str]:
    """
    Normalize a hex color to lowercase #RRGGBB format
    
    Args:
        color: Color string to normalize
        
    Returns:
        Normalized color or None if invalid
        
    Examples:
        >>> normalize_hex_color("#667EEA")
        '#667eea'
        >>> normalize_hex_color("#fff")
        '#ffffff'
        >>> normalize_hex_color("invalid")
        None
    """
    if not is_valid_hex_color(color):
        return None
    
    color = color.lower()
    
    # Expand 3-digit hex to 6-digit
    if len(color) == 4:  # #RGB
        r, g, b = color[1], color[2], color[3]
        color = f"#{r}{r}{g}{g}{b}{b}"
    
    return color


def assign_color_from_palette(existing_colors: List[str]) -> str:
    """
    Assign a color from the palette that's not already in use
    
    Args:
        existing_colors: List of colors already assigned to destinations
        
    Returns:
        A color from the palette (cycles through if all are used)
        
    Examples:
        >>> assign_color_from_palette([])
        '#667eea'
        >>> assign_color_from_palette(["#667eea", "#f093fb"])
        '#4facfe'
        >>> # If all 20 colors are used, cycles through
        >>> assign_color_from_palette(COLOR_PALETTE)
        '#667eea'
    """
    # Normalize existing colors for comparison
    normalized_existing = {normalize_hex_color(c) for c in existing_colors if c}
    
    # Find first available color from palette
    for color in COLOR_PALETTE:
        if color not in normalized_existing:
            return color
    
    # All colors used, cycle through palette
    # Use modulo to wrap around
    used_count = len(existing_colors)
    return COLOR_PALETTE[used_count % len(COLOR_PALETTE)]


def get_next_available_color(existing_colors: List[str], preferred_color: Optional[str] = None) -> str:
    """
    Get the next available color, preferring the provided color if available
    
    Args:
        existing_colors: List of colors already assigned
        preferred_color: Color to use if available (optional)
        
    Returns:
        The preferred color if available and valid, otherwise next available color
        
    Examples:
        >>> get_next_available_color([], "#667eea")
        '#667eea'
        >>> get_next_available_color(["#667eea"], "#667eea")
        '#f093fb'
        >>> get_next_available_color([], "invalid")
        '#667eea'
    """
    # If preferred color is provided and valid
    if preferred_color:
        normalized = normalize_hex_color(preferred_color)
        if normalized:
            # Check if it's already in use
            normalized_existing = {normalize_hex_color(c) for c in existing_colors if c}
            if normalized not in normalized_existing:
                return normalized
    
    # Preferred color not available or invalid, assign from palette
    return assign_color_from_palette(existing_colors)


if __name__ == "__main__":
    # Test color validation
    print("Testing color validation:")
    print(f"  #667eea: {is_valid_hex_color('#667eea')}")  # True
    print(f"  #fff: {is_valid_hex_color('#fff')}")  # True
    print(f"  667eea: {is_valid_hex_color('667eea')}")  # False
    print(f"  #gggggg: {is_valid_hex_color('#gggggg')}")  # False
    
    # Test color normalization
    print("\nTesting color normalization:")
    print(f"  #667EEA -> {normalize_hex_color('#667EEA')}")  # #667eea
    print(f"  #fff -> {normalize_hex_color('#fff')}")  # #ffffff
    print(f"  invalid -> {normalize_hex_color('invalid')}")  # None
    
    # Test color assignment
    print("\nTesting color assignment:")
    print(f"  No colors used: {assign_color_from_palette([])}")  # #667eea
    print(f"  First two used: {assign_color_from_palette(['#667eea', '#f093fb'])}")  # #4facfe
    print(f"  All colors used: {assign_color_from_palette(COLOR_PALETTE)}")  # #667eea (cycles)
    
    # Test next available color
    print("\nTesting next available color:")
    print(f"  Preferred available: {get_next_available_color([], '#667eea')}")  # #667eea
    print(f"  Preferred taken: {get_next_available_color(['#667eea'], '#667eea')}")  # #f093fb
    print(f"  Invalid preferred: {get_next_available_color([], 'invalid')}")  # #667eea
