#!/bin/bash

# Kiosk Session Script for Device Monitor
# This script starts the kiosk environment and launches the device monitor application

# Enable logging
exec > >(tee -a /var/log/kiosk-session.log) 2>&1
echo "$(date): Starting kiosk session for user $(whoami)"

# Wait for X server to be ready
while ! xset q &>/dev/null; do
    echo "$(date): Waiting for X server..."
    sleep 1
done

# Disable screen saver and power management
echo "$(date): Configuring display settings..."
xset s off
xset -dpms
xset s noblank

# Hide cursor globally
echo "$(date): Starting cursor hiding..."
unclutter -idle 0.1 -root &

# Disable Alt+Tab, Ctrl+Alt+T, etc.
echo "$(date): Configuring keyboard shortcuts..."
setxkbmap -option terminate:ctrl_alt_bksp

# Start window manager (lightweight)
echo "$(date): Starting window manager..."
openbox-session &
WM_PID=$!

# Wait for window manager to initialize
sleep 3

# Set background color to black
xsetroot -solid black 2>/dev/null || true

# Disable window decorations and borders
if command -v wmctrl >/dev/null 2>&1; then
    # If wmctrl is available, use it to manage windows
    sleep 2
    wmctrl -k on 2>/dev/null || true
fi

# Function to start the kiosk application
start_application() {
    echo "$(date): Starting Device Monitor application..."
    cd /opt/device-monitor
    export DISPLAY=:0
    export KIOSK=1
    export PYTHONPATH="/opt/device-monitor:$PYTHONPATH"
    
    # Start the application with proper environment
    /usr/bin/python3 /opt/device-monitor/main.py --kiosk &
    APP_PID=$!
    echo "$(date): Application started with PID: $APP_PID"
    
    # Wait for application to finish
    wait $APP_PID
    APP_EXIT_CODE=$?
    echo "$(date): Application exited with code: $APP_EXIT_CODE"
    
    return $APP_EXIT_CODE
}

# Main loop - restart application if it crashes
echo "$(date): Entering main application loop..."
while true; do
    start_application
    
    # If application exits, wait a moment and restart
    echo "$(date): Application stopped. Restarting in 5 seconds..."
    sleep 5
done

# Cleanup (this shouldn't be reached in normal operation)
echo "$(date): Cleaning up kiosk session..."
kill $WM_PID 2>/dev/null || true