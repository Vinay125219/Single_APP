# Device Monitor - Build Instructions

This document provides comprehensive instructions for building Device Monitor executables both locally and via CI/CD pipeline.

## 🎯 Overview

The build system creates **4 different executables**:

1. **Linux Normal** - Standard GUI application for Linux
2. **Linux Kiosk** - Kiosk mode with auto-boot for Linux RHEL 7.9
3. **Windows Normal** - Standard GUI application for Windows
4. **Windows Kiosk** - Kiosk mode with Windows service for Windows 10/11

## 🚀 Quick Start

### Using GitHub Actions (Recommended)

1. **Push to repository** or **create a tag**:

   ```bash
   # For development build
   git push origin main

   # For release build
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Manual trigger** (via GitHub web interface):
   - Go to Actions → Build Device Monitor Executables
   - Click "Run workflow"
   - Set version (optional)

### Local Building

#### Windows:

```cmd
cd scripts
build_local.bat --mode all --version 1.0.0
```

#### Linux:

```bash
cd scripts
chmod +x build_local.sh
./build_local.sh --mode all --version 1.0.0
```

## 📋 Prerequisites

### For Local Building

#### Windows Requirements:

- Windows 10/11
- Python 3.7+
- pip (Python package manager)

#### Linux Requirements:

- Linux (Ubuntu/RHEL/CentOS)
- Python 3.6+
- pip3
- Development tools: `sudo apt-get install python3-tk python3-dev build-essential`

### For CI/CD (GitHub Actions)

- GitHub repository with Actions enabled
- No additional setup required

## 🔧 Build Configuration

### Configuration File: `build_config.json`

```json
{
  "app_name": "device_monitor",
  "version": "1.0.0",
  "platforms": {
    "linux": {
      "executable_name": "device_monitor_linux",
      "upx": true
    },
    "windows": {
      "executable_name": "device_monitor_windows",
      "upx": true,
      "version_info": true
    }
  },
  "modes": {
    "normal": {
      "description": "Standard GUI application"
    },
    "kiosk": {
      "description": "Kiosk mode with auto-boot functionality"
    }
  }
}
```

### Dependencies: `requirements.txt`

```txt
pywin32>=227; sys_platform == "win32"
pyinstaller>=5.0
```

## 🏗️ Build Process Details

### 1. Mode-Specific Wrappers

Each executable gets a mode-specific wrapper:

**Normal Mode:**

- Removes kiosk environment variables
- Removes `--kiosk` command line arguments
- Runs in standard GUI mode

**Kiosk Mode:**

- Sets `KIOSK=1` environment variable
- Adds `--kiosk` command line argument
- Configures for kiosk operation

### 2. Platform-Specific Features

**Linux Builds:**

- No Windows dependencies
- Optimized for X11 display systems
- Compatible with RHEL 7.9+

**Windows Builds:**

- Includes Windows service components
- Registry manipulation capabilities
- Windows-specific GUI optimizations

### 3. PyInstaller Configuration

Each build creates a custom `.spec` file with:

- Hidden imports for all required modules
- Data files (main.py, service files)
- Platform-specific optimizations
- Version information (Windows only)

## 📦 Output Structure

### CI/CD Artifacts

```
Artifacts/
├── device-monitor-linux-normal-v1.0.0/
│   └── device_monitor_linux_normal_v1.0.0.tar.gz
├── device-monitor-linux-kiosk-v1.0.0/
│   └── device_monitor_linux_kiosk_v1.0.0.tar.gz
├── device-monitor-windows-normal-v1.0.0/
│   └── device_monitor_windows_normal_v1.0.0.zip
└── device-monitor-windows-kiosk-v1.0.0/
    └── device_monitor_windows_kiosk_v1.0.0.zip
```

### Local Build Output

```
release/
├── linux-normal/
│   ├── device_monitor_linux_normal
│   └── README.txt
├── linux-kiosk/
│   ├── device_monitor_linux_kiosk
│   ├── linux/                    # Installation scripts
│   ├── kiosk.sh                  # Wrapper script
│   └── README.txt
├── windows-normal/
│   ├── device_monitor_windows_normal.exe
│   └── README.txt
├── windows-kiosk/
│   ├── device_monitor_windows_kiosk.exe
│   ├── windows/                  # Installation scripts
│   ├── kiosk.bat                 # Wrapper script
│   └── README.txt
├── device_monitor_linux_normal_v1.0.0.tar.gz
├── device_monitor_linux_kiosk_v1.0.0.tar.gz
├── device_monitor_windows_normal_v1.0.0.zip
└── device_monitor_windows_kiosk_v1.0.0.zip
```

## 🛠️ Local Build Commands

### Basic Commands

```bash
# Build all executables for current platform
python scripts/build_local.py

# Build specific mode
python scripts/build_local.py --mode kiosk

# Build with version
python scripts/build_local.py --version 1.0.0

# Skip testing and packaging (faster for development)
python scripts/build_local.py --no-test --no-package
```

### Platform-Specific Scripts

**Windows:**

```cmd
scripts\build_local.bat
scripts\build_local.bat --mode kiosk --version 1.0.0
```

**Linux:**

```bash
scripts/build_local.sh
scripts/build_local.sh --mode kiosk --version 1.0.0
```

## 🔄 CI/CD Pipeline Details

### GitHub Actions Workflow: `.github/workflows/build-executables.yml`

#### Triggers:

- Push to `main` or `develop` branches
- Push tags starting with `v` (e.g., `v1.0.0`)
- Pull requests to `main`
- Manual workflow dispatch

#### Build Matrix:

- **Platforms:** Linux (ubuntu-latest), Windows (windows-latest)
- **Modes:** normal, kiosk
- **Total Jobs:** 4 concurrent builds

#### Steps per Job:

1. **Checkout code**
2. **Set up Python 3.9**
3. **Install system dependencies**
4. **Install Python dependencies**
5. **Create version info**
6. **Prepare build scripts**
7. **Build executable with PyInstaller**
8. **Test executable**
9. **Create release package**
10. **Upload artifacts**

#### Release Creation:

- **Automatic:** On version tags (`v*`)
- **Manual:** Via workflow dispatch
- **Assets:** All 4 executables with documentation

### Build Performance

| Platform | Mode   | Typical Build Time | Executable Size |
| -------- | ------ | ------------------ | --------------- |
| Linux    | Normal | ~3-5 minutes       | ~25-35 MB       |
| Linux    | Kiosk  | ~3-5 minutes       | ~25-35 MB       |
| Windows  | Normal | ~4-6 minutes       | ~30-40 MB       |
| Windows  | Kiosk  | ~4-6 minutes       | ~30-40 MB       |

## 🧪 Testing

### Automated Testing

Each build includes automated testing:

- **Executable creation verification**
- **Basic startup test** (timeout after 5-10 seconds)
- **Help argument test**

### Manual Testing

After building, test each executable:

**Linux:**

```bash
# Normal mode
./device_monitor_linux_normal

# Kiosk mode
DISPLAY=:0 ./device_monitor_linux_kiosk
```

**Windows:**

```cmd
REM Normal mode
device_monitor_windows_normal.exe

REM Kiosk mode
device_monitor_windows_kiosk.exe
```

## 🚨 Troubleshooting

### Common Build Issues

1. **PyInstaller not found:**

   ```bash
   pip install pyinstaller
   ```

2. **Missing Python modules:**

   ```bash
   pip install -r requirements.txt
   ```

3. **Windows: pywin32 issues:**

   ```cmd
   pip install --force-reinstall pywin32
   python Scripts/pywin32_postinstall.py -install
   ```

4. **Linux: tkinter missing:**
   ```bash
   sudo apt-get install python3-tk
   ```

### Build Script Issues

1. **Permission denied (Linux):**

   ```bash
   chmod +x scripts/build_local.sh
   ```

2. **Wrong directory:**

   - Ensure you're in the project root where `main.py` exists

3. **Memory issues during build:**
   - Close other applications
   - Try building one mode at a time

### CI/CD Issues

1. **Workflow not triggering:**

   - Check branch names and tag formats
   - Verify workflow file syntax

2. **Build failures:**

   - Check GitHub Actions logs
   - Verify dependencies in `requirements.txt`

3. **Artifact upload issues:**
   - Check file paths in workflow
   - Verify artifact names are unique

## 📊 Build Optimization

### Reducing Executable Size

1. **UPX Compression** (enabled by default):

   - Reduces size by ~50-70%
   - May slightly increase startup time

2. **Exclude unused modules:**

   - Update `exclude_modules` in `build_config.json`

3. **Strip debug symbols:**
   - Set `"strip": true` in build configuration

### Faster Build Times

1. **Local development:**

   ```bash
   python scripts/build_local.py --no-clean --no-test --no-package
   ```

2. **Skip cross-platform builds:**

   ```bash
   python scripts/build_local.py --platform current
   ```

3. **Build specific mode only:**
   ```bash
   python scripts/build_local.py --mode normal
   ```

## 🔐 Security Considerations

### Code Signing (Optional)

For production releases, consider code signing:

**Windows:**

- Add certificate to PyInstaller spec
- Use `signtool` for signing

**macOS:**

- Use Apple Developer certificate
- Notarize the application

### Build Verification

- Verify checksums of built executables
- Test on clean systems
- Scan with antivirus (some may flag PyInstaller executables)

## 📚 Additional Resources

- [PyInstaller Documentation](https://pyinstaller.readthedocs.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Python Packaging Guide](https://packaging.python.org/)

## 🤝 Contributing

When contributing build-related changes:

1. Test builds on both platforms if possible
2. Update build configuration if adding dependencies
3. Update this documentation for any process changes
4. Test CI/CD pipeline with a draft release

---

**Ready to build?** Start with the [Quick Start](#-quick-start) section above! 🚀
