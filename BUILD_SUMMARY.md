# GUARD - Kiosk Mode Application Build Summary

## Output Files Structure

### 1. Windows:

- **release/windows-normal/**
  - `guard.exe` (Normal mode executable)
  - `guard-setup-normal.exe` (Normal mode installer)
- **release/windows-kiosk/**
  - `guard-kiosk.exe` (Kiosk mode executable)
  - `guard-setup-kiosk.exe` (Kiosk mode installer)

### 2. Linux (RHEL 7.9):

- **release/linux-normal/**
  - `guard` (Normal mode executable)
  - `guard-*.rpm` (RPM package)
- **release/linux-kiosk/**
  - `guard-kiosk` (Kiosk mode executable)
  - `guard-*.rpm` (RPM package)

## Build Process

The CI/CD pipeline now correctly builds 4 output files as requested:

- 2 Windows installers (normal and kiosk mode)
- 2 Linux packages (normal and kiosk mode)

Each release directory contains the appropriate executable and installer/package for that platform and mode.
