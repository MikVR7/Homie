#!/usr/bin/env python3
"""
Script to assign colors to existing destinations that don't have one.

This should be run once after the color feature is deployed to assign
colors to all existing destinations in the database.
"""

import sqlite3
import logging
from pathlib import Path
import sys

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from file_organizer.color_palette import assign_color_from_palette

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("AssignColors")


def assign_colors_to_existing_destinations(db_path: Path):
    """
    Assign colors to all existing destinations that don't have one.
    
    Args:
        db_path: Path to the database file
    """
    if not db_path.exists():
        logger.error(f"Database not found at {db_path}")
        return False
    
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    
    try:
        # Get all destinations without colors
        cursor = conn.execute("""
            SELECT id, user_id, path, category, color
            FROM destinations
            WHERE is_active = 1
            ORDER BY user_id, created_at
        """)
        
        all_destinations = cursor.fetchall()
        
        if not all_destinations:
            logger.info("No destinations found in database")
            return True
        
        logger.info(f"Found {len(all_destinations)} total destinations")
        
        # Group by user_id to assign colors per user
        users = {}
        for dest in all_destinations:
            user_id = dest['user_id']
            if user_id not in users:
                users[user_id] = []
            users[user_id].append(dest)
        
        total_updated = 0
        
        # Process each user's destinations
        for user_id, destinations in users.items():
            logger.info(f"\nProcessing user: {user_id}")
            logger.info(f"  Total destinations: {len(destinations)}")
            
            # Get existing colors for this user
            existing_colors = [d['color'] for d in destinations if d['color']]
            logger.info(f"  Destinations with colors: {len(existing_colors)}")
            
            # Find destinations without colors
            destinations_without_colors = [d for d in destinations if not d['color']]
            logger.info(f"  Destinations without colors: {len(destinations_without_colors)}")
            
            if not destinations_without_colors:
                logger.info(f"  ✅ All destinations already have colors")
                continue
            
            # Assign colors to destinations without colors
            for dest in destinations_without_colors:
                # Assign next available color
                new_color = assign_color_from_palette(existing_colors)
                existing_colors.append(new_color)  # Track for next iteration
                
                # Update destination in database
                conn.execute("""
                    UPDATE destinations
                    SET color = ?
                    WHERE id = ?
                """, (new_color, dest['id']))
                
                logger.info(f"  ✅ Assigned {new_color} to: {dest['category']} ({dest['path']})")
                total_updated += 1
        
        # Commit all changes
        conn.commit()
        
        logger.info(f"\n{'='*60}")
        logger.info(f"✅ Successfully assigned colors to {total_updated} destinations")
        logger.info(f"{'='*60}")
        
        return True
        
    except Exception as e:
        conn.rollback()
        logger.error(f"Error assigning colors: {e}", exc_info=True)
        return False
        
    finally:
        conn.close()


def verify_colors(db_path: Path):
    """
    Verify that all active destinations have colors.
    
    Args:
        db_path: Path to the database file
    """
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    
    try:
        # Count destinations with and without colors
        cursor = conn.execute("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN color IS NOT NULL THEN 1 ELSE 0 END) as with_color,
                SUM(CASE WHEN color IS NULL THEN 1 ELSE 0 END) as without_color
            FROM destinations
            WHERE is_active = 1
        """)
        
        result = cursor.fetchone()
        
        logger.info(f"\n{'='*60}")
        logger.info(f"VERIFICATION RESULTS")
        logger.info(f"{'='*60}")
        logger.info(f"Total active destinations: {result['total']}")
        logger.info(f"Destinations with colors: {result['with_color']}")
        logger.info(f"Destinations without colors: {result['without_color']}")
        
        if result['without_color'] == 0:
            logger.info(f"✅ All destinations have colors!")
        else:
            logger.warning(f"⚠️  {result['without_color']} destinations still missing colors")
        
        logger.info(f"{'='*60}")
        
        return result['without_color'] == 0
        
    finally:
        conn.close()


if __name__ == "__main__":
    # Path to the database
    db_path = Path("backend/data/modules/homie_file_organizer.db")
    
    logger.info("="*60)
    logger.info("ASSIGNING COLORS TO EXISTING DESTINATIONS")
    logger.info("="*60)
    
    # Assign colors
    success = assign_colors_to_existing_destinations(db_path)
    
    if success:
        # Verify all destinations have colors
        verify_colors(db_path)
    else:
        logger.error("Failed to assign colors")
        sys.exit(1)
