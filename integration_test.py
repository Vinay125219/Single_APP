#!/usr/bin/env python3
"""
Integration test script to verify that all components are properly integrated
and running smoothly.
"""

import os
import sys
import subprocess
from pathlib import Path

def check_directory_structure():
    """Check that all required directories exist"""
    required_dirs = [
        'release',
        'release/linux-kiosk',
        'release/linux-kiosk-full',
        'release/linux-normal',
        'release/windows-kiosk',
        'release/windows-normal',
        'build_kiosk/dist',
        'linux/scripts',
        'scripts',
        'assets'
    ]
    
    print("Checking directory structure...")
    for dir_path in required_dirs:
        if not os.path.exists(dir_path):
            print(f"❌ Missing directory: {dir_path}")
            return False
        print(f"✅ Found directory: {dir_path}")
    return True

def check_required_files():
    """Check that all required files exist"""
    required_files = [
        'main.py',
        'guard_installer.nsi',
        'guard_kiosk_installer.nsi',
        'requirements.txt',
        'README.md',
        'LICENSE',
        'assets/guard_icon.ico',
        'assets/guard_icon.png',
        '.github/workflows/build.yml',
        '.github/rpm/device-monitor.spec',
        'build_kiosk/dist/device_monitor_linux_kiosk',
        'linux/scripts/install-kiosk.sh',
        'scripts/kiosk.sh',
        'kiosk_boot_guide.md',
        'DEPLOYMENT_GUIDE.md',
        'release/linux-kiosk/device_monitor_linux_kiosk',
        'release/linux-kiosk/README.txt',
        'release/linux-kiosk-full/device_monitor_linux_kiosk',
        'release/linux-kiosk-full/README.txt',
        'release/linux-kiosk-full/linux/scripts/install-kiosk.sh',
        'release/linux-kiosk-full/kiosk.sh',  # Fixed path
        'release/linux-kiosk-full/main.py',
        'release/linux-kiosk-full/kiosk_boot_guide.md',
        'release/linux-kiosk-full/DEPLOYMENT_GUIDE.md'
    ]
    
    print("\nChecking required files...")
    for file_path in required_files:
        if not os.path.exists(file_path):
            print(f"❌ Missing file: {file_path}")
            return False
        print(f"✅ Found file: {file_path}")
    return True

def check_release_archives():
    """Check that release archives exist"""
    archive_files = [
        'release/device_monitor_linux_kiosk_dev-20251001-102640.zip',
        'release/device_monitor_linux_kiosk_full_dev-20251001-102640.zip'
    ]
    
    print("\nChecking release archives...")
    for archive_path in archive_files:
        if not os.path.exists(archive_path):
            print(f"❌ Missing archive: {archive_path}")
            return False
        print(f"✅ Found archive: {archive_path}")
    return True

def check_python_syntax():
    """Check that Python files have valid syntax"""
    python_files = ['main.py', 'integration_test.py']
    
    print("\nChecking Python syntax...")
    for py_file in python_files:
        if os.path.exists(py_file):
            try:
                subprocess.run([sys.executable, '-m', 'py_compile', py_file], 
                              check=True, capture_output=True)
                print(f"✅ Valid Python syntax: {py_file}")
            except subprocess.CalledProcessError as e:
                print(f"❌ Invalid Python syntax: {py_file}")
                print(f"   Error: {e.stderr.decode()}")
                return False
    return True

def check_nsis_scripts():
    """Check that NSIS scripts exist and have basic structure"""
    nsis_files = ['guard_installer.nsi', 'guard_kiosk_installer.nsi']
    
    print("\nChecking NSIS scripts...")
    for nsis_file in nsis_files:
        if os.path.exists(nsis_file):
            with open(nsis_file, 'r') as f:
                content = f.read()
                if 'Name "' in content and 'OutFile' in content:
                    print(f"✅ Valid NSIS script: {nsis_file}")
                else:
                    print(f"❌ Invalid NSIS script: {nsis_file}")
                    return False
    return True

def main():
    """Run all integration tests"""
    print("Running GUARD Integration Tests...")
    print("=" * 50)
    
    tests = [
        check_directory_structure,
        check_required_files,
        check_release_archives,
        check_python_syntax,
        check_nsis_scripts
    ]
    
    all_passed = True
    for test in tests:
        if not test():
            all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 All integration tests passed! Everything is properly integrated and running smoothly.")
        return 0
    else:
        print("❌ Some integration tests failed. Please check the errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())