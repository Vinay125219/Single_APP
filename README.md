# Device Monitor Kiosk Implementation - README

## Overview

This project provides a comprehensive kiosk boot implementation for the Device Monitor application, supporting both **Linux RHEL 7.9** and **Windows** platforms. The implementation ensures automatic startup on system boot with a locked-down kiosk environment.

## Features

### Core Functionality

- ✅ Auto-boot on system startup
- ✅ Automatic user login
- ✅ Locked-down kiosk environment
- ✅ Application auto-restart on crash
- ✅ Comprehensive logging
- ✅ Emergency exit mechanisms
- ✅ Easy installation and uninstallation

### Linux RHEL 7.9 Features

- Systemd service integration
- GDM/LightDM auto-login configuration
- Custom X11 session with Openbox window manager
- Security limits and user restrictions
- Automatic application restart on failure

### Windows Features

- Windows Service implementation
- Registry-based kiosk restrictions
- Group Policy integration (Pro/Enterprise)
- Advanced user session management
- Auto-login configuration

## Quick Start

### For Linux RHEL 7.9:

```bash
cd linux/scripts
sudo ./install-kiosk.sh
sudo reboot
```

### For Windows:

```powershell
# Run as Administrator
cd windows\scripts
.\install-kiosk.ps1 -Install
# Reboot system
```

📖 **See [QUICK_START.md](QUICK_START.md) for detailed quick start instructions.**

## Documentation

| Document                                   | Description                       |
| ------------------------------------------ | --------------------------------- |
| [QUICK_START.md](QUICK_START.md)           | Fast setup for both platforms     |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Comprehensive deployment guide    |
| [kiosk_boot_guide.md](kiosk_boot_guide.md) | Original implementation reference |

## Project Structure

```
Single_APP/
├── main.py                     # Main Device Monitor application
├── README.md                   # This file
├── QUICK_START.md             # Quick setup guide
├── DEPLOYMENT_GUIDE.md        # Comprehensive guide
├── kiosk_boot_guide.md        # Original reference
├── scripts/                   # Enhanced basic scripts
│   ├── kiosk.bat             # Enhanced Windows wrapper
│   └── kiosk.sh              # Enhanced Linux wrapper
├── linux/                    # Linux RHEL 7.9 implementation
│   ├── systemd/              # Systemd service files
│   ├── config/               # Configuration files
│   └── scripts/              # Installation and management scripts
└── windows/                  # Windows implementation
    ├── service/              # Windows service implementation
    └── scripts/              # Installation and management scripts
```

## Platform Support

| Platform   | Version | Status          | Features                        |
| ---------- | ------- | --------------- | ------------------------------- |
| Linux RHEL | 7.9     | ✅ Full Support | Systemd, X11, Auto-login        |
| Windows    | 10/11   | ✅ Full Support | Service, Registry, Group Policy |
| Windows    | 7/8     | ⚠️ Limited      | Basic registry configuration    |

## Prerequisites

### Linux RHEL 7.9

- Root access
- Python 3.6+
- X11 display server
- GDM or LightDM display manager

### Windows

- Administrator privileges
- Python 3.7+
- PowerShell 5.0+

## Installation Methods

### Automated Installation (Recommended)

- **Linux**: `sudo ./linux/scripts/install-kiosk.sh`
- **Windows**: `.\windows\scripts\install-kiosk.ps1 -Install`

### Manual Installation

Follow the step-by-step instructions in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

## Security Features

### Linux Security

- Dedicated kiosk user with minimal privileges
- System resource limits
- Disabled virtual terminals
- Custom X11 session restrictions

### Windows Security

- Registry-based system lockdown
- Disabled system functions (Task Manager, etc.)
- User session restrictions
- Group Policy enforcement (Pro/Enterprise)

## Management Commands

### Linux Commands

```bash
# Service management
sudo systemctl status device-monitor-kiosk.service
sudo systemctl start device-monitor-kiosk.service
sudo systemctl stop device-monitor-kiosk.service

# Testing
sudo /opt/device-monitor/test-kiosk.sh

# Logs
sudo journalctl -u device-monitor-kiosk.service -f
```

### Windows Commands

```powershell
# Service management
Get-Service DeviceMonitorKiosk
Start-Service DeviceMonitorKiosk
Stop-Service DeviceMonitorKiosk

# Testing
.\test-kiosk.bat

# Logs
Get-EventLog -LogName Application -Source DeviceMonitorKiosk
```

## Emergency Exit

If you get locked in kiosk mode:

- **Linux**: Press `Ctrl+Alt+Shift+Q`
- **Windows**: Press `Ctrl+Alt+K`

## Troubleshooting

### Common Issues

1. **Application won't start**: Check Python installation and dependencies
2. **Service fails**: Review service logs and permissions
3. **Auto-login fails**: Verify display manager configuration
4. **Kiosk restrictions not working**: Check registry/policy settings

### Diagnostic Tools

- **Linux**: `./linux/scripts/test-kiosk.sh`
- **Windows**: `.\windows\scripts\test-kiosk.bat`

### Getting Help

1. Run the diagnostic/test scripts
2. Check the comprehensive [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
3. Review system and application logs
4. Verify all prerequisites are met

## Uninstallation

### Linux

```bash
sudo /opt/device-monitor/uninstall-kiosk.sh
```

### Windows

```powershell
& "C:\Program Files\DeviceMonitor\uninstall-kiosk.ps1"
```

## Development and Testing

### Testing Changes

1. Test in a virtual machine first
2. Use the provided test scripts
3. Verify all functionality before production deployment

### Customization

- Modify configuration files in `linux/config/` or `windows/scripts/`
- Update service definitions as needed
- Adjust security settings based on requirements

## Contributing

When making changes:

1. Test on both platforms
2. Update documentation
3. Follow the existing code structure
4. Add appropriate logging

## License

This implementation follows the same license as the main Device Monitor application.

## Support

For issues or questions:

1. Check the troubleshooting sections
2. Review the comprehensive documentation
3. Use the diagnostic tools provided
4. Check system-specific logs and configurations

---

**🚀 Ready to deploy? Start with [QUICK_START.md](QUICK_START.md) for the fastest setup experience!**
