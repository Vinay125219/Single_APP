# GUARD - General USB Automated Response and Device monitoring

GUARD is a Python tkinter-based GUI application for USB device monitoring and system control. It supports both normal mode and kiosk mode for secure environments.

## Features

- USB device monitoring for specific device types (4750, 4761)
- Application launching and monitoring
- System control (shutdown, restart)
- Kiosk mode for secure environments
- Cross-platform support (Windows and Linux)

## Installation

### Windows

Download and run the installer (`guard-setup.exe`) to install GUARD on Windows.

### Linux (RHEL 7.9)

Install the RPM package using:

```bash
sudo rpm -i guard-1.0.0-1.el7.x86_64.rpm
```

## Usage

### Normal Mode

Run GUARD normally to use all features with standard window controls.

### Kiosk Mode

To run in kiosk mode:

- **Windows**: Use the "GUARD Kiosk Mode" shortcut or run `guard.exe --kiosk`
- **Linux**: The application will automatically start in kiosk mode if installed via RPM

In kiosk mode:

- The application runs fullscreen with no window decorations
- Common exit key combinations are disabled
- Press `Ctrl+Shift+K` to exit kiosk mode

## Building from Source

### Prerequisites

- Python 3.6+
- pip packages: `tkinter`, `pyinstaller`

### Build Steps

1. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

2. Build executable:
   ```bash
   pyinstaller --onefile --noconsole main.py -n guard
   ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
