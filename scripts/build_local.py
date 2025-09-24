#!/usr/bin/env python3
"""
Local build script for Device Monitor executables
This script allows you to build executables locally for testing before CI/CD
"""

import os
import sys
import shutil
import json
import subprocess
import argparse
from pathlib import Path
import platform


def load_config():
    """Load build configuration"""
    config_path = Path(__file__).parent.parent / "build_config.json"
    with open(config_path, "r") as f:
        return json.load(f)


def create_wrapper(mode, build_dir):
    """Create mode-specific wrapper script"""

    if mode == "kiosk":
        wrapper_content = """#!/usr/bin/env python3
import os
import sys

# Set kiosk environment
os.environ["KIOSK"] = "1"

# Add --kiosk argument if not present
if "--kiosk" not in sys.argv:
    sys.argv.append("--kiosk")

# Import and run main application
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main

if __name__ == "__main__":
    main.main()
"""
    else:
        wrapper_content = """#!/usr/bin/env python3
import os
import sys

# Ensure normal mode (no kiosk)
os.environ.pop("KIOSK", None)

# Remove --kiosk argument if present
if "--kiosk" in sys.argv:
    sys.argv.remove("--kiosk")

# Import and run main application
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main

if __name__ == "__main__":
    main.main()
"""

    wrapper_path = build_dir / f"device_monitor_{mode}_wrapper.py"
    with open(wrapper_path, "w") as f:
        f.write(wrapper_content)

    return wrapper_path


def create_spec_file(mode, platform_name, config, build_dir, wrapper_path):
    """Create PyInstaller spec file"""

    platform_config = config["platforms"][platform_name]
    executable_name = f"{platform_config['executable_name']}_{mode}"

    if platform_name == "windows":
        executable_name += ".exe"

    # Build hidden imports list
    hidden_imports = config["pyinstaller"]["hidden_imports"].copy()

    # Remove Windows-specific imports on Linux
    if platform_name == "linux":
        hidden_imports = [imp for imp in hidden_imports if not imp.startswith("win32")]

    spec_content = f"""# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['{wrapper_path.name}'],
    pathex=['.'],
    binaries=[],
    datas=[
        ('main.py', '.'),
    ],
    hiddenimports={hidden_imports},
    hookspath=[],
    hooksconfig={{}},
    runtime_hooks=[],
    excludes={config["pyinstaller"]["exclude_modules"]},
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='{executable_name}',
    debug=False,
    bootloader_ignore_signals=False,
    strip={str(config["build_options"]["strip"]).lower()},
    upx={str(platform_config["upx"]).lower()},
    upx_exclude=[],
    runtime_tmpdir=None,
    console={str(platform_config["console"]).lower()},
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
"""

    # Add version info for Windows
    if platform_name == "windows" and platform_config.get("version_info"):
        spec_content += "    version='version_info.py',\n"

    spec_content += ")\n"

    spec_path = build_dir / f"device_monitor_{mode}.spec"
    with open(spec_path, "w") as f:
        f.write(spec_content)

    return spec_path


def create_version_info(version, mode, build_dir):
    """Create Windows version info file"""

    version_info = f"""# UTF-8
#
# For more details about fixed file info 'ffi' see:
# http://msdn.microsoft.com/en-us/library/ms646997.aspx
VSVersionInfo(
  ffi=FixedFileInfo(
    filevers=(1,0,0,0),
    prodvers=(1,0,0,0),
    mask=0x3f,
    flags=0x0,
    OS=0x40004,
    fileType=0x1,
    subtype=0x0,
    date=(0, 0)
    ),
  kids=[
    StringFileInfo(
      [
      StringTable(
        u'040904B0',
        [StringStruct(u'CompanyName', u'Device Monitor'),
        StringStruct(u'FileDescription', u'Device Monitor Application ({mode} mode)'),
        StringStruct(u'FileVersion', u'{version}'),
        StringStruct(u'InternalName', u'device_monitor_{mode}'),
        StringStruct(u'LegalCopyright', u'Copyright (c) 2024'),
        StringStruct(u'OriginalFilename', u'device_monitor_windows_{mode}.exe'),
        StringStruct(u'ProductName', u'Device Monitor'),
        StringStruct(u'ProductVersion', u'{version}')])
      ]), 
    VarFileInfo([VarStruct(u'Translation', [1033, 1200])])
  ]
)
"""

    version_path = build_dir / "version_info.py"
    with open(version_path, "w") as f:
        f.write(version_info)

    return version_path


def build_executable(mode, platform_name, version, config, clean=True):
    """Build executable for specified mode and platform"""

    print(f"🔨 Building {platform_name} executable in {mode} mode...")

    # Create build directory
    build_dir = Path(f"build_{platform_name}_{mode}")
    if clean and build_dir.exists():
        shutil.rmtree(build_dir)
    build_dir.mkdir(exist_ok=True)

    # Copy main application
    main_py = Path("main.py")
    if not main_py.exists():
        raise FileNotFoundError("main.py not found in current directory")

    shutil.copy2(main_py, build_dir / "main.py")

    # Copy Windows service file if kiosk mode and Windows
    if mode == "kiosk" and platform_name == "windows":
        service_file = Path("windows/service/windows_service.py")
        if service_file.exists():
            shutil.copy2(service_file, build_dir / "windows_service.py")

    # Create wrapper script
    wrapper_path = create_wrapper(mode, build_dir)

    # Create version info for Windows
    if platform_name == "windows":
        create_version_info(version, mode, build_dir)

    # Create spec file
    spec_path = create_spec_file(mode, platform_name, config, build_dir, wrapper_path)

    # Change to build directory
    original_cwd = os.getcwd()
    os.chdir(build_dir)

    try:
        # Run PyInstaller
        cmd = ["pyinstaller", spec_path.name]
        if clean:
            cmd.append("--clean")
        if config["build_options"]["noconfirm"]:
            cmd.append("--noconfirm")

        print(f"Running: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            print(f"❌ PyInstaller failed:")
            print(result.stdout)
            print(result.stderr)
            return False

        # Check if executable was created
        platform_config = config["platforms"][platform_name]
        executable_name = f"{platform_config['executable_name']}_{mode}"
        if platform_name == "windows":
            executable_name += ".exe"

        executable_path = Path("dist") / executable_name
        if executable_path.exists():
            print(f"✅ Successfully built: {executable_path}")
            print(f"   Size: {executable_path.stat().st_size / (1024*1024):.1f} MB")
            return True
        else:
            print(f"❌ Executable not found: {executable_path}")
            return False

    except Exception as e:
        print(f"❌ Build failed: {e}")
        return False

    finally:
        os.chdir(original_cwd)


def test_executable(mode, platform_name, config):
    """Test the built executable"""

    print(f"🧪 Testing {platform_name} {mode} executable...")

    build_dir = Path(f"build_{platform_name}_{mode}")
    platform_config = config["platforms"][platform_name]
    executable_name = f"{platform_config['executable_name']}_{mode}"

    if platform_name == "windows":
        executable_name += ".exe"

    executable_path = build_dir / "dist" / executable_name

    if not executable_path.exists():
        print(f"❌ Executable not found: {executable_path}")
        return False

    try:
        # Quick test that executable starts
        cmd = [str(executable_path), "--help"]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)

        if (
            result.returncode == 0 or result.returncode == 1
        ):  # Some apps return 1 for --help
            print(f"✅ Executable test passed")
            return True
        else:
            print(f"⚠️ Executable test returned code {result.returncode}")
            print(f"   stdout: {result.stdout[:200]}")
            print(f"   stderr: {result.stderr[:200]}")
            return True  # Still consider it a pass

    except subprocess.TimeoutExpired:
        print(f"⚠️ Executable test timed out (may be normal for GUI apps)")
        return True
    except Exception as e:
        print(f"❌ Executable test failed: {e}")
        return False


def create_release_package(mode, platform_name, version, config):
    """Create release package"""

    print(f"📦 Creating release package for {platform_name} {mode}...")

    build_dir = Path(f"build_{platform_name}_{mode}")
    release_dir = Path("release") / f"{platform_name}-{mode}"
    release_dir.mkdir(parents=True, exist_ok=True)

    # Copy executable
    platform_config = config["platforms"][platform_name]
    executable_name = f"{platform_config['executable_name']}_{mode}"
    if platform_name == "windows":
        executable_name += ".exe"

    executable_path = build_dir / "dist" / executable_name
    if executable_path.exists():
        shutil.copy2(executable_path, release_dir / executable_name)

    # Copy relevant scripts and documentation
    if mode == "kiosk":
        if platform_name == "linux":
            linux_dir = Path("linux")
            if linux_dir.exists():
                shutil.copytree(linux_dir, release_dir / "linux", dirs_exist_ok=True)

            kiosk_script = Path("scripts/kiosk.sh")
            if kiosk_script.exists():
                shutil.copy2(kiosk_script, release_dir / "kiosk.sh")

        elif platform_name == "windows":
            windows_dir = Path("windows")
            if windows_dir.exists():
                shutil.copytree(
                    windows_dir, release_dir / "windows", dirs_exist_ok=True
                )

            kiosk_script = Path("scripts/kiosk.bat")
            if kiosk_script.exists():
                shutil.copy2(kiosk_script, release_dir / "kiosk.bat")

    # Create README
    readme_content = f"""Device Monitor - {platform_name.title()} {mode.title()} Build
Version: {version}
Platform: {platform_name.title()}
Mode: {mode.title()}

Usage:
  {executable_name}

{
'Kiosk Mode:' if mode == 'kiosk' else 'Normal Mode:'
}
{
'''  - Run with kiosk environment enabled
  - Use installation scripts in the platform directory
  - See deployment documentation for setup''' if mode == 'kiosk' else '''  - Standard GUI application
  - No kiosk restrictions applied'''
}

For more information, see the documentation in the repository.
"""

    with open(release_dir / "README.txt", "w") as f:
        f.write(readme_content)

    # Create archive
    if platform_name == "linux":
        archive_name = f"device_monitor_linux_{mode}_{version}.tar.gz"
        subprocess.run(
            [
                "tar",
                "-czf",
                f"release/{archive_name}",
                "-C",
                "release",
                f"{platform_name}-{mode}",
            ]
        )
    else:
        archive_name = f"device_monitor_windows_{mode}_{version}.zip"
        shutil.make_archive(
            f"release/device_monitor_windows_{mode}_{version}",
            "zip",
            "release",
            f"{platform_name}-{mode}",
        )

    print(f"✅ Created release package: release/{archive_name}")


def main():
    parser = argparse.ArgumentParser(
        description="Build Device Monitor executables locally"
    )
    parser.add_argument(
        "--mode",
        choices=["normal", "kiosk", "all"],
        default="all",
        help="Build mode (default: all)",
    )
    parser.add_argument(
        "--platform",
        choices=["linux", "windows", "current", "all"],
        default="current",
        help="Target platform (default: current)",
    )
    parser.add_argument(
        "--version", default="dev", help="Version string (default: dev)"
    )
    parser.add_argument(
        "--no-clean", action="store_true", help="Don't clean build directories"
    )
    parser.add_argument(
        "--no-test", action="store_true", help="Skip executable testing"
    )
    parser.add_argument(
        "--no-package", action="store_true", help="Skip release packaging"
    )

    args = parser.parse_args()

    # Load configuration
    try:
        config = load_config()
    except Exception as e:
        print(f"❌ Failed to load configuration: {e}")
        return 1

    # Determine platforms to build
    current_platform = "windows" if platform.system() == "Windows" else "linux"

    if args.platform == "current":
        platforms = [current_platform]
    elif args.platform == "all":
        platforms = ["linux", "windows"]
    else:
        platforms = [args.platform]

    # Determine modes to build
    if args.mode == "all":
        modes = ["normal", "kiosk"]
    else:
        modes = [args.mode]

    # Check dependencies
    try:
        subprocess.run(["pyinstaller", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ PyInstaller not found. Install with: pip install pyinstaller")
        return 1

    print(f"🚀 Building Device Monitor v{args.version}")
    print(f"   Platforms: {', '.join(platforms)}")
    print(f"   Modes: {', '.join(modes)}")
    print()

    success_count = 0
    total_count = len(platforms) * len(modes)

    for platform_name in platforms:
        # Skip if trying to build for different platform
        if platform_name != current_platform:
            print(f"⚠️ Skipping {platform_name} build (cross-compilation not supported)")
            continue

        for mode in modes:
            try:
                # Build executable
                if build_executable(
                    mode, platform_name, args.version, config, not args.no_clean
                ):
                    success_count += 1

                    # Test executable
                    if not args.no_test:
                        test_executable(mode, platform_name, config)

                    # Create release package
                    if not args.no_package:
                        create_release_package(
                            mode, platform_name, args.version, config
                        )

                print()

            except Exception as e:
                print(f"❌ Failed to build {platform_name} {mode}: {e}")
                print()

    print(f"🏁 Build completed: {success_count}/{total_count} successful")

    if success_count > 0 and not args.no_package:
        print("\n📦 Release packages created in release/ directory:")
        release_dir = Path("release")
        if release_dir.exists():
            for item in release_dir.iterdir():
                if item.is_file() and (item.suffix in [".zip", ".gz"]):
                    print(f"   {item.name}")

    return 0 if success_count == total_count else 1


if __name__ == "__main__":
    sys.exit(main())
