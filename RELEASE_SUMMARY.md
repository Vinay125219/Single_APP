# GUARD - Kiosk Mode Application Release Structure

## Directory Structure

```
release/
├── linux-kiosk/
│   ├── guard-kiosk (Kiosk mode executable)
│   └── guard-1.0.0-1.el7.x86_64.rpm (RPM package)
├── linux-normal/
│   ├── guard (Normal mode executable)
│   └── guard-1.0.0-1.el7.x86_64.rpm (RPM package)
├── windows-kiosk/
│   ├── guard-kiosk.exe (Kiosk mode executable)
│   └── guard-setup-kiosk.exe (Kiosk mode installer)
└── windows-normal/
    ├── guard.exe (Normal mode executable)
    └── guard-setup-normal.exe (Normal mode installer)
```

## Fixed Issues

1. **Directory Structure Problem**: Fixed the CI/CD pipeline error where it was trying to copy from a non-existent `linux/` directory
2. **Proper File Organization**: Created the exact directory structure requested with separate folders for each platform and mode
3. **Cross-Platform Support**: Organized files for both Windows (.exe/.msi) and Linux (RPM) as required

## CI/CD Pipeline Improvements

The updated GitHub Actions workflow now:

1. **Builds separate executables** for normal and kiosk modes on both platforms
2. **Creates proper installers** for Windows using NSIS scripts
3. **Generates RPM packages** for Linux with kiosk mode support
4. **Organizes output** in the exact structure requested:
   - 2 Windows installers (normal and kiosk mode)
   - 2 Linux packages (normal and kiosk mode)
5. **Validates directory structure** with listing commands to ensure correctness

## Kiosk Mode Features

### Windows

- **System Lockdown**: Registry modifications to disable Task Manager and other system functions
- **Secure Exit**: Hidden key combination (Ctrl+Shift+K) to safely exit kiosk mode
- **Separate Installers**: Distinct installers for normal and kiosk modes

### Linux (RHEL 7.9)

- **Autostart Integration**: RPM packages with autostart entries for kiosk mode
- **Secure Exit**: Hidden key combination (Ctrl+Shift+K) to safely exit kiosk mode
- **Package Management**: Proper RPM packages for easy installation

The build process now correctly produces all 4 required output files without errors.
