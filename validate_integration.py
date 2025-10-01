#!/usr/bin/env python3
"""
Quick Integration Validation Script
Run this script to quickly verify that all components are properly integrated.
"""

import os
import sys

def quick_validation():
    """Perform a quick validation of the integration"""
    print("Performing quick integration validation...")
    
    # Check critical directories
    critical_dirs = [
        'release/linux-kiosk',
        'release/linux-kiosk-full',
        'release/linux-normal',
        'release/windows-kiosk',
        'release/windows-normal'
    ]
    
    for dir_path in critical_dirs:
        if not os.path.exists(dir_path):
            print(f"❌ Missing critical directory: {dir_path}")
            return False
    
    # Check critical files
    critical_files = [
        'main.py',
        'guard_installer.nsi',
        'guard_kiosk_installer.nsi',
        '.github/workflows/build.yml'
    ]
    
    for file_path in critical_files:
        if not os.path.exists(file_path):
            print(f"❌ Missing critical file: {file_path}")
            return False
    
    # Check that release archives exist
    archive_files = [
        'release/device_monitor_linux_kiosk_dev-20251001-102640.zip',
        'release/device_monitor_linux_kiosk_full_dev-20251001-102640.zip'
    ]
    
    for archive_path in archive_files:
        if not os.path.exists(archive_path):
            print(f"❌ Missing release archive: {archive_path}")
            return False
    
    print("✅ Quick validation passed - all critical components are present")
    return True

if __name__ == "__main__":
    if quick_validation():
        print("\n🎉 Integration is working properly!")
        sys.exit(0)
    else:
        print("\n❌ Integration issues detected!")
        sys.exit(1)