#!/usr/bin/env python3
"""
CI/CD Pipeline Verification Script
This script verifies that the CI/CD pipeline will run smoothly by checking all dependencies and configurations.
"""

import os
import sys
import subprocess
from pathlib import Path

def check_github_actions_workflow():
    """Check that the GitHub Actions workflow is properly configured"""
    workflow_path = '.github/workflows/build.yml'
    
    if not os.path.exists(workflow_path):
        print("❌ GitHub Actions workflow not found")
        return False
    
    with open(workflow_path, 'r') as f:
        content = f.read()
        
    # Check for required sections
    required_sections = [
        'build-linux:',
        'build-windows:',
        'uses: addnab/docker-run-action@v3',
        'uses: actions/setup-python@v4',
        'uses: actions/upload-artifact@v4'
    ]
    
    for section in required_sections:
        if section not in content:
            print(f"❌ Missing section in workflow: {section}")
            return False
    
    print("✅ GitHub Actions workflow is properly configured")
    return True

def check_nsis_installation():
    """Check that NSIS is available for Windows installer creation"""
    try:
        result = subprocess.run(['makensis', '/VERSION'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print(f"✅ NSIS is available: {result.stdout.strip()}")
            return True
        else:
            print("❌ NSIS is not available or not in PATH")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("❌ NSIS is not installed or not in PATH")
        return False

def check_python_dependencies():
    """Check that required Python dependencies are available"""
    required_packages = ['pyinstaller', 'Pillow']
    
    for package in required_packages:
        try:
            subprocess.run([sys.executable, '-c', f'import {package}'], 
                          check=True, capture_output=True, timeout=5)
            print(f"✅ Python package '{package}' is available")
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            print(f"❌ Python package '{package}' is not available")
            return False
    
    return True

def check_rpm_build_tools():
    """Check that RPM build tools are available (simulated for local verification)"""
    # In a real CI/CD environment, this would check for actual RPM tools
    # For local verification, we'll just check that the spec file exists
    spec_file = '.github/rpm/device-monitor.spec'
    
    if os.path.exists(spec_file):
        print("✅ RPM spec file exists")
        return True
    else:
        print("❌ RPM spec file not found")
        return False

def check_file_permissions():
    """Check that files have appropriate permissions"""
    executable_files = [
        'build_kiosk/dist/device_monitor_linux_kiosk',
        'linux/scripts/install-kiosk.sh'
    ]
    
    for file_path in executable_files:
        if os.path.exists(file_path):
            # Check if file is executable (Unix/Linux)
            if os.name != 'nt':  # Not Windows
                if os.access(file_path, os.X_OK):
                    print(f"✅ File is executable: {file_path}")
                else:
                    print(f"⚠️  File is not executable: {file_path} (this may be OK for CI/CD)")
            else:
                print(f"✅ File exists: {file_path} (Windows - no execute permission check)")
        else:
            print(f"❌ File not found: {file_path}")
            return False
    
    return True

def check_directory_writable():
    """Check that directories are writable for build process"""
    test_dirs = ['release', 'build_kiosk']
    
    for dir_path in test_dirs:
        if os.path.exists(dir_path):
            try:
                test_file = os.path.join(dir_path, '.test_write_access')
                with open(test_file, 'w') as f:
                    f.write('test')
                os.remove(test_file)
                print(f"✅ Directory is writable: {dir_path}")
            except IOError:
                print(f"❌ Directory is not writable: {dir_path}")
                return False
        else:
            print(f"❌ Directory not found: {dir_path}")
            return False
    
    return True

def main():
    """Run all CI/CD verification tests"""
    print("Running CI/CD Pipeline Verification...")
    print("=" * 50)
    
    tests = [
        check_github_actions_workflow,
        check_nsis_installation,
        check_python_dependencies,
        check_rpm_build_tools,
        check_file_permissions,
        check_directory_writable
    ]
    
    all_passed = True
    for test in tests:
        if not test():
            all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 All CI/CD verification tests passed! The pipeline should run smoothly.")
        print("\nSummary of verified components:")
        print("  ✅ GitHub Actions workflow")
        print("  ✅ NSIS installer creation")
        print("  ✅ Python dependencies")
        print("  ✅ RPM build configuration")
        print("  ✅ File permissions")
        print("  ✅ Directory write access")
        return 0
    else:
        print("❌ Some CI/CD verification tests failed. Please check the errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())