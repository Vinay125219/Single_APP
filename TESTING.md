# GUARD Kiosk Mode Testing Plan

## Overview

This document outlines the testing procedures for verifying the kiosk mode functionality of the GUARD application on both Windows and RHEL 7.9 platforms.

## Test Environment

- Windows 10/11
- RHEL 7.9
- GUARD application with kiosk mode support

## Test Cases

### 1. Windows Kiosk Mode Testing

#### 1.1 Installation

- [ ] Install GUARD using the Windows installer
- [ ] Verify that the application installs correctly
- [ ] Check that both normal and kiosk mode shortcuts are created

#### 1.2 Normal Mode Functionality

- [ ] Launch GUARD in normal mode
- [ ] Verify that all UI elements are accessible
- [ ] Test USB device monitoring functionality
- [ ] Test application launching feature
- [ ] Test system control functions (shutdown, restart)
- [ ] Verify that fullscreen can be toggled with F11/Escape

#### 1.3 Kiosk Mode Activation

- [ ] Launch GUARD using the kiosk mode shortcut
- [ ] Verify that the application starts in fullscreen mode
- [ ] Confirm that window decorations are hidden
- [ ] Verify that the kiosk mode indicator is visible

#### 1.4 Kiosk Mode Restrictions

- [ ] Attempt to exit using Alt+F4 (should be blocked)
- [ ] Attempt to exit using Ctrl+W (should be blocked)
- [ ] Attempt to exit using Ctrl+Q (should be blocked)
- [ ] Attempt to access Task Manager (should be blocked)
- [ ] Attempt to access Start Menu (should be blocked)

#### 1.5 Kiosk Mode Exit

- [ ] Use the hidden key combination (Ctrl+Shift+K) to exit kiosk mode
- [ ] Confirm exit prompt appears
- [ ] Verify that application closes properly

#### 1.6 System Integration

- [ ] Verify that registry entries are correctly set for kiosk mode
- [ ] Confirm that registry entries are correctly removed when exiting kiosk mode

### 2. RHEL 7.9 Kiosk Mode Testing

#### 2.1 Installation

- [ ] Install GUARD using the RPM package
- [ ] Verify that the application installs correctly
- [ ] Check that desktop entries are created

#### 2.2 Normal Mode Functionality

- [ ] Launch GUARD in normal mode
- [ ] Verify that all UI elements are accessible
- [ ] Test USB device monitoring functionality
- [ ] Test application launching feature
- [ ] Test system control functions (shutdown, restart)
- [ ] Verify that fullscreen can be toggled with F11/Escape

#### 2.3 Kiosk Mode Activation

- [ ] Launch GUARD with the --kiosk flag
- [ ] Verify that the application starts in fullscreen mode
- [ ] Confirm that window decorations are hidden
- [ ] Verify that the kiosk mode indicator is visible

#### 2.4 Kiosk Mode Restrictions

- [ ] Attempt to exit using Alt+F4 (should be blocked)
- [ ] Attempt to exit using Ctrl+W (should be blocked)
- [ ] Attempt to exit using Ctrl+Q (should be blocked)
- [ ] Attempt to access system shortcuts (should be blocked)

#### 2.5 Kiosk Mode Exit

- [ ] Use the hidden key combination (Ctrl+Shift+K) to exit kiosk mode
- [ ] Confirm exit prompt appears
- [ ] Verify that application closes properly

#### 2.6 System Integration

- [ ] Verify that autostart entries are correctly created
- [ ] Confirm that autostart entries are correctly removed when exiting kiosk mode

### 3. Cross-Platform Functionality

#### 3.1 Consistent UI

- [ ] Verify that the UI looks and behaves consistently on both platforms
- [ ] Confirm that all features work identically on both platforms

#### 3.2 USB Device Monitoring

- [ ] Test with actual USB devices (4750, 4761)
- [ ] Verify that device detection works correctly
- [ ] Confirm that device status updates in real-time

#### 3.3 Application Launching

- [ ] Test launching various types of applications
- [ ] Verify that launched applications run correctly
- [ ] Confirm that application termination works properly

## Test Results

### Windows

| Test Case               | Status | Notes |
| ----------------------- | ------ | ----- |
| Installation            |        |       |
| Normal Mode             |        |       |
| Kiosk Mode Activation   |        |       |
| Kiosk Mode Restrictions |        |       |
| Kiosk Mode Exit         |        |       |
| System Integration      |        |       |

### RHEL 7.9

| Test Case               | Status | Notes |
| ----------------------- | ------ | ----- |
| Installation            |        |       |
| Normal Mode             |        |       |
| Kiosk Mode Activation   |        |       |
| Kiosk Mode Restrictions |        |       |
| Kiosk Mode Exit         |        |       |
| System Integration      |        |       |

### Cross-Platform

| Test Case             | Status | Notes |
| --------------------- | ------ | ----- |
| Consistent UI         |        |       |
| USB Device Monitoring |        |       |
| Application Launching |        |       |
