#!/bin/bash

# Device Monitor Kiosk Testing Script for RHEL 7.9
# This script provides various testing and troubleshooting utilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Test service status
test_service() {
    log "Testing systemd service..."
    
    echo "Service status:"
    systemctl status device-monitor-kiosk.service || true
    echo ""
    
    echo "Service enabled status:"
    systemctl is-enabled device-monitor-kiosk.service || true
    echo ""
    
    echo "Recent service logs:"
    journalctl -u device-monitor-kiosk.service --no-pager -n 20 || true
}

# Test display manager configuration
test_display_manager() {
    log "Testing display manager configuration..."
    
    if systemctl is-enabled gdm &>/dev/null; then
        echo "GDM is enabled"
        if [[ -f /etc/gdm/custom.conf ]]; then
            echo "GDM configuration found:"
            cat /etc/gdm/custom.conf
        else
            warn "GDM configuration not found"
        fi
    elif systemctl is-enabled lightdm &>/dev/null; then
        echo "LightDM is enabled"
        if [[ -f /etc/lightdm/lightdm.conf ]]; then
            echo "LightDM configuration found:"
            cat /etc/lightdm/lightdm.conf
        else
            warn "LightDM configuration not found"
        fi
    else
        warn "No supported display manager found"
    fi
}

# Test kiosk user
test_kiosk_user() {
    log "Testing kiosk user configuration..."
    
    if id kioskuser &>/dev/null; then
        echo "Kiosk user exists:"
        id kioskuser
        echo ""
        echo "Kiosk user home directory:"
        ls -la /home/kioskuser/ || true
        echo ""
        echo "Kiosk user Openbox configuration:"
        if [[ -f /home/kioskuser/.config/openbox/rc.xml ]]; then
            echo "Openbox config found"
        else
            warn "Openbox config not found"
        fi
    else
        error "Kiosk user does not exist"
    fi
}

# Test application files
test_application() {
    log "Testing application installation..."
    
    if [[ -d /opt/device-monitor ]]; then
        echo "Application directory exists:"
        ls -la /opt/device-monitor/
        echo ""
        
        if [[ -f /opt/device-monitor/main.py ]]; then
            echo "Main application file found"
            if [[ -x /opt/device-monitor/main.py ]]; then
                echo "Main application is executable"
            else
                warn "Main application is not executable"
            fi
        else
            error "Main application file not found"
        fi
        
        if [[ -f /opt/device-monitor/kiosk-session.sh ]]; then
            echo "Kiosk session script found"
            if [[ -x /opt/device-monitor/kiosk-session.sh ]]; then
                echo "Kiosk session script is executable"
            else
                warn "Kiosk session script is not executable"
            fi
        else
            warn "Kiosk session script not found"
        fi
    else
        error "Application directory does not exist"
    fi
}

# Test Python environment
test_python() {
    log "Testing Python environment..."
    
    echo "Python3 version:"
    python3 --version || error "Python3 not found"
    echo ""
    
    echo "Python3 tkinter test:"
    python3 -c "import tkinter; print('tkinter available')" || warn "tkinter not available"
    echo ""
    
    echo "Python3 modules test:"
    python3 -c "
import sys
modules = ['threading', 'subprocess', 'os', 'time', 'queue', 'logging', 'pathlib', 'json']
for module in modules:
    try:
        __import__(module)
        print(f'{module}: OK')
    except ImportError:
        print(f'{module}: MISSING')
" || warn "Some Python modules missing"
}

# Test X11 environment
test_x11() {
    log "Testing X11 environment..."
    
    echo "X11 packages:"
    rpm -qa | grep -E "(xorg|openbox|unclutter|wmctrl)" | sort || warn "Some X11 packages may be missing"
    echo ""
    
    echo "Display manager status:"
    systemctl status display-manager || true
}

# Manual test functions
manual_test_session() {
    log "Starting manual session test (as kioskuser)..."
    echo "This will switch to the kiosk user and test the session manually."
    echo "Press Ctrl+C to cancel, or Enter to continue..."
    read
    
    sudo -u kioskuser bash -c "
        export DISPLAY=:0
        export KIOSK=1
        cd /opt/device-monitor
        echo 'Testing kiosk session script...'
        timeout 10s ./kiosk-session.sh || echo 'Session test completed or timed out'
    "
}

manual_test_app() {
    log "Starting manual application test (as kioskuser)..."
    echo "This will start the application manually for testing."
    echo "Press Ctrl+C to cancel, or Enter to continue..."
    read
    
    sudo -u kioskuser bash -c "
        export DISPLAY=:0
        export KIOSK=1
        cd /opt/device-monitor
        echo 'Starting application...'
        timeout 30s python3 main.py --kiosk || echo 'Application test completed or timed out'
    "
}

# Show usage
show_usage() {
    echo "Device Monitor Kiosk Testing Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  service     - Test systemd service"
    echo "  display     - Test display manager configuration"
    echo "  user        - Test kiosk user configuration"
    echo "  app         - Test application installation"
    echo "  python      - Test Python environment"
    echo "  x11         - Test X11 environment"
    echo "  session     - Manual session test"
    echo "  apptest     - Manual application test"
    echo "  all         - Run all automatic tests"
    echo "  help        - Show this help"
    echo ""
}

# Run all automatic tests
run_all_tests() {
    log "Running all automatic tests..."
    echo ""
    
    test_service
    echo ""
    test_display_manager
    echo ""
    test_kiosk_user
    echo ""
    test_application
    echo ""
    test_python
    echo ""
    test_x11
    
    echo ""
    log "All automatic tests completed"
}

# Main function
main() {
    case "${1:-all}" in
        service)
            test_service
            ;;
        display)
            test_display_manager
            ;;
        user)
            test_kiosk_user
            ;;
        app)
            test_application
            ;;
        python)
            test_python
            ;;
        x11)
            test_x11
            ;;
        session)
            manual_test_session
            ;;
        apptest)
            manual_test_app
            ;;
        all)
            run_all_tests
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo "Unknown command: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"