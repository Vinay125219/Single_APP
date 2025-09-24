#!/bin/bash

# Enhanced Device Monitor Kiosk Script for Linux
# This script provides robust kiosk functionality with logging and error handling

set -e

# Configuration
APP_NAME="main.py"
APP_PATH="$(dirname "$0")/../$APP_NAME"
LOG_FILE="$(dirname "$0")/../kiosk.log"
MAX_RESTARTS=10
RESTART_DELAY=5
RESTART_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

# Ensure we're in the correct directory
cd "$(dirname "$0")/.."

log "Device Monitor Kiosk Started"
log "Application Path: $APP_PATH"
log "Working Directory: $(pwd)"

# Function to check if application exists
check_application() {
    if [[ ! -f "$APP_PATH" ]]; then
        log_error "Application file not found: $APP_PATH"
        return 1
    fi
    
    if [[ ! -x "$APP_PATH" ]] && ! command -v python3 >/dev/null; then
        log_error "Python3 not found and application is not executable"
        return 1
    fi
    
    return 0
}

# Function to start the application
start_application() {
    log "Starting Device Monitor Application (attempt $((RESTART_COUNT + 1))/$MAX_RESTARTS)"
    
    # Set environment variables for kiosk mode
    export KIOSK=1
    export DISPLAY=${DISPLAY:-:0}
    
    # Start the application
    if [[ "$APP_PATH" == *.py ]]; then
        python3 "$APP_PATH" --kiosk
    else
        "$APP_PATH" --kiosk
    fi
    
    return $?
}

# Main loop
while true; do
    # Check if we've exceeded maximum restarts
    if [[ $RESTART_COUNT -ge $MAX_RESTARTS ]]; then
        log_error "Maximum restart attempts reached ($MAX_RESTARTS)"
        log_error "System may have a persistent issue. Please check logs."
        echo -e "${RED}Press Enter to reset counter or Ctrl+C to exit...${NC}"
        read
        RESTART_COUNT=0
        continue
    fi
    
    # Check if application exists
    if ! check_application; then
        log_error "Application check failed. Waiting 10 seconds before retry..."
        sleep 10
        continue
    fi
    
    # Start the application
    start_application
    EXIT_CODE=$?
    
    log "Application exited with code: $EXIT_CODE"
    
    # Handle different exit codes
    if [[ $EXIT_CODE -eq 0 ]]; then
        log "Normal application exit"
        RESTART_COUNT=0
    elif [[ $EXIT_CODE -eq 130 ]]; then
        log "Application interrupted by user (Ctrl+C)"
        log "Exiting kiosk mode"
        break
    else
        log_warn "Application error exit (code: $EXIT_CODE)"
        ((RESTART_COUNT++))
    fi
    
    log "Restarting in $RESTART_DELAY seconds..."
    echo -e "${YELLOW}Application will restart in $RESTART_DELAY seconds...${NC}"
    sleep $RESTART_DELAY
done

log "Kiosk mode exited"
