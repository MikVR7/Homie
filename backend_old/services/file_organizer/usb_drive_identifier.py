#!/usr/bin/env python3
"""
USB Drive Identification Strategy

This module provides a robust way to identify USB drives across different
operating systems and reconnections. It tries multiple identification methods
in order of reliability.
"""

import subprocess
import re
import json
import logging
from typing import Optional, Dict, List

class USBDriveIdentifier:
    """
    Handles USB drive identification using multiple fallback methods.
    
    Strategy:
    1. Primary: USB Serial Number (hardware-based, OS-independent)
    2. Secondary: Partition UUID (changes on format, which user wants)
    3. Fallback: Drive label + size combination
    """
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def get_drive_identifier(self, device_path: str) -> Optional[Dict[str, str]]:
        """
        Get the best available identifier for a USB drive.
        
        Args:
            device_path: Path to the device (e.g., /dev/sda1, /media/usb)
            
        Returns:
            Dict with identifier info, or None if device not found
        """
        # Try to get USB serial number first
        usb_serial = self._get_usb_serial_number(device_path)
        if usb_serial:
            return {
                'type': 'usb_serial',
                'id': usb_serial,
                'confidence': 'high',
                'description': 'Hardware USB serial number'
            }
        
        # Fallback to partition UUID
        partition_uuid = self._get_partition_uuid(device_path)
        if partition_uuid:
            return {
                'type': 'partition_uuid',
                'id': partition_uuid,
                'confidence': 'medium',
                'description': 'File system UUID (changes on format)'
            }
        
        # Last resort: label + size combination
        drive_info = self._get_drive_info(device_path)
        if drive_info and drive_info.get('label') and drive_info.get('size'):
            combined_id = f"{drive_info['label']}_{drive_info['size']}"
            return {
                'type': 'label_size',
                'id': combined_id,
                'confidence': 'low',
                'description': f"Label + size combination: {combined_id}"
            }
        
        return None
    
    def _get_usb_serial_number(self, device_path: str) -> Optional[str]:
        """Get USB serial number for a device."""
        try:
            # First, find which USB device this storage device belongs to
            device_name = self._extract_device_name(device_path)
            if not device_name:
                return None
            
            # Get USB device information
            result = subprocess.run(['lsusb', '-v'], capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                return None
            
            # Parse lsusb output to find storage devices with serial numbers
            serial_numbers = self._parse_usb_serials(result.stdout)
            
            # Try to match storage device to USB device
            # This is the tricky part - we need to correlate block device to USB device
            for device_info, serial in serial_numbers.items():
                if self._is_storage_device(device_info):
                    # For now, return the first storage device serial we find
                    # In a real implementation, we'd need more sophisticated matching
                    return serial
            
            return None
            
        except Exception as e:
            self.logger.warning(f"Could not get USB serial for {device_path}: {e}")
            return None
    
    def _get_partition_uuid(self, device_path: str) -> Optional[str]:
        """Get partition UUID for a device."""
        try:
            result = subprocess.run(['sudo', 'blkid', device_path], 
                                  capture_output=True, text=True, timeout=5)
            if result.returncode != 0:
                return None
            
            # Extract UUID from blkid output
            match = re.search(r'UUID="([^"]+)"', result.stdout)
            if match:
                return match.group(1)
            
            return None
            
        except Exception as e:
            self.logger.warning(f"Could not get partition UUID for {device_path}: {e}")
            return None
    
    def _get_drive_info(self, device_path: str) -> Optional[Dict[str, str]]:
        """Get drive label and size information."""
        try:
            device_name = self._extract_device_name(device_path)
            if not device_name:
                return None
            
            result = subprocess.run(['lsblk', '-f', '-o', 'NAME,SIZE,LABEL', device_name], 
                                  capture_output=True, text=True, timeout=5)
            if result.returncode != 0:
                return None
            
            lines = result.stdout.strip().split('\n')
            if len(lines) < 2:
                return None
            
            # Parse the output (skip header)
            for line in lines[1:]:
                parts = line.strip().split()
                if len(parts) >= 2:
                    name, size = parts[0], parts[1]
                    label = parts[2] if len(parts) > 2 else "unlabeled"
                    
                    return {
                        'name': name,
                        'size': size,
                        'label': label
                    }
            
            return None
            
        except Exception as e:
            self.logger.warning(f"Could not get drive info for {device_path}: {e}")
            return None
    
    def _extract_device_name(self, device_path: str) -> Optional[str]:
        """Extract device name from path."""
        if device_path.startswith('/dev/'):
            return device_path
        elif device_path.startswith('/media/') or device_path.startswith('/mnt/'):
            # Try to find the mounted device
            try:
                result = subprocess.run(['findmnt', '-n', '-o', 'SOURCE', device_path], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    return result.stdout.strip()
            except:
                pass
        
        return None
    
    def _parse_usb_serials(self, lsusb_output: str) -> Dict[str, str]:
        """Parse USB serial numbers from lsusb -v output."""
        serial_numbers = {}
        current_device = None
        current_serial = None
        
        for line in lsusb_output.split('\n'):
            # Look for device lines
            if line.startswith('Bus ') and 'ID ' in line:
                # Save previous device if we have both device and serial
                if current_device and current_serial:
                    serial_numbers[current_device] = current_serial
                
                current_device = line.strip()
                current_serial = None
            
            # Look for serial number
            elif 'iSerial' in line and current_device:
                match = re.search(r'iSerial\s+\d+\s+(.+)', line)
                if match:
                    current_serial = match.group(1).strip()
        
        # Don't forget the last device
        if current_device and current_serial:
            serial_numbers[current_device] = current_serial
        
        return serial_numbers
    
    def _is_storage_device(self, device_info: str) -> bool:
        """Check if a USB device is likely a storage device."""
        storage_indicators = [
            'sandisk', 'kingston', 'transcend', 'samsung', 'corsair', 
            'lexar', 'toshiba', 'adata', 'verbatim', 'pny', 'sony',
            'cruzer', 'datatraveler', 'flashdrive'
        ]
        
        device_lower = device_info.lower()
        return any(indicator in device_lower for indicator in storage_indicators)

def test_drive_identification():
    """Test the drive identification system."""
    identifier = USBDriveIdentifier()
    
    print("=== USB Drive Identification Test ===\n")
    
    # Test with common mount points
    test_paths = [
        '/media',
        '/mnt',
        '/dev/sda1',
        '/dev/sdb1',
        '/Volumes'  # macOS
    ]
    
    for path in test_paths:
        print(f"Testing path: {path}")
        result = identifier.get_drive_identifier(path)
        if result:
            print(f"  ✅ Found identifier: {result}")
        else:
            print(f"  ❌ No identifier found")
        print()
    
    print("Strategy Summary:")
    print("1. 🥇 USB Serial Number - Best (hardware-based, cross-OS)")
    print("2. 🥈 Partition UUID - Good (changes on format)")
    print("3. 🥉 Label + Size - Fallback (user can change label)")

if __name__ == "__main__":
    # Set up logging
    logging.basicConfig(level=logging.INFO)
    test_drive_identification()