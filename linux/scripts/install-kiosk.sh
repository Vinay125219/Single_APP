#!/bin/bash

# Device Monitor Kiosk Installation Script for RHEL 7.9
# This script sets up the complete kiosk environment

set -e

# Configuration
KIOSK_USER="kioskuser"
KIOSK_GROUP="kioskuser"
KIOSK_UID="1001"
APP_DIR="/opt/device-monitor"
CONFIG_DIR="$(dirname "$0")/../config"
SCRIPTS_DIR="$(dirname "$0")/../scripts"
SYSTEMD_DIR="$(dirname "$0")/../systemd"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/var/log/kiosk-install.log"

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

# Check RHEL version
check_rhel_version() {
    if [[ ! -f /etc/redhat-release ]]; then
        error "This script is designed for RHEL systems"
    fi
    
    local version=$(cat /etc/redhat-release | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    if [[ ! "$version" =~ ^7\.[0-9]+$ ]]; then
        warn "This script is optimized for RHEL 7.x. Current version: $version"
    fi
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    
    # Update system
    yum update -y
    
    # Install required packages
    yum install -y \
        python3 \
        python3-pip \
        python3-tkinter \
        openbox \
        unclutter \
        wmctrl \
        xorg-x11-server-Xorg \
        xorg-x11-xinit \
        xorg-x11-utils \
        gdm \
        systemd
    
    # Install Python dependencies
    pip3 install --upgrade pip
    # Add any specific Python packages your application needs here
    
    log "Package installation completed"
}

# Create kiosk user
create_kiosk_user() {
    log "Creating kiosk user..."
    
    if id "$KIOSK_USER" &>/dev/null; then
        warn "User $KIOSK_USER already exists"
    else
        useradd -m -u $KIOSK_UID -s /bin/bash "$KIOSK_USER"
        usermod -aG users "$KIOSK_USER"
        log "User $KIOSK_USER created successfully"
    fi
    
    # Set up user directories
    mkdir -p "/home/$KIOSK_USER/.config/openbox"
    mkdir -p "/home/$KIOSK_USER/.local/share/applications"
    chown -R "$KIOSK_USER:$KIOSK_GROUP" "/home/$KIOSK_USER"
}

# Install application
install_application() {
    log "Installing Device Monitor application..."
    
    # Create application directory
    mkdir -p "$APP_DIR"
    
    # Copy main application file
    cp "$(dirname "$0")/../../main.py" "$APP_DIR/"
    
    # Set permissions
    chmod +x "$APP_DIR/main.py"
    chown -R "$KIOSK_USER:$KIOSK_GROUP" "$APP_DIR"
    
    log "Application installed to $APP_DIR"
}

# Configure systemd service
configure_systemd() {
    log "Configuring systemd service..."
    
    # Copy service file
    cp "$SYSTEMD_DIR/device-monitor-kiosk.service" /etc/systemd/system/
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable device-monitor-kiosk.service
    
    log "Systemd service configured and enabled"
}

# Configure display manager
configure_display_manager() {
    log "Configuring display manager..."
    
    # Detect display manager
    if systemctl is-enabled gdm &>/dev/null; then
        log "Configuring GDM..."
        cp "$CONFIG_DIR/gdm-custom.conf" /etc/gdm/custom.conf
    elif systemctl is-enabled lightdm &>/dev/null; then
        log "Configuring LightDM..."
        cp "$CONFIG_DIR/lightdm.conf" /etc/lightdm/lightdm.conf
    else
        warn "No supported display manager found. Manual configuration required."
    fi
}

# Configure kiosk session
configure_kiosk_session() {
    log "Configuring kiosk session..."
    
    # Copy session files
    cp "$CONFIG_DIR/kiosk-session.desktop" /usr/share/xsessions/
    cp "$SCRIPTS_DIR/kiosk-session.sh" "$APP_DIR/"
    chmod +x "$APP_DIR/kiosk-session.sh"
    
    # Copy Openbox configuration
    cp "$CONFIG_DIR/openbox-rc.xml" "/home/$KIOSK_USER/.config/openbox/rc.xml"
    chown "$KIOSK_USER:$KIOSK_GROUP" "/home/$KIOSK_USER/.config/openbox/rc.xml"
    
    log "Kiosk session configured"
}

# Configure security limits
configure_security() {
    log "Configuring security limits..."
    
    # Copy limits configuration
    cp "$CONFIG_DIR/kiosk-limits.conf" /etc/security/limits.d/
    
    # Disable virtual terminals (keep only one)
    if [[ -f /etc/systemd/logind.conf ]]; then
        sed -i 's/#NAutoVTs=6/NAutoVTs=1/' /etc/systemd/logind.conf
        sed -i 's/#ReserveVT=6/ReserveVT=1/' /etc/systemd/logind.conf
    fi
    
    log "Security configuration applied"
}

# Create uninstall script
create_uninstall_script() {
    log "Creating uninstall script..."
    
    cat > /opt/device-monitor/uninstall-kiosk.sh << 'EOF'
#!/bin/bash

# Uninstall Device Monitor Kiosk

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Uninstalling Device Monitor Kiosk..."

# Stop and disable service
systemctl stop device-monitor-kiosk.service || true
systemctl disable device-monitor-kiosk.service || true

# Remove service file
rm -f /etc/systemd/system/device-monitor-kiosk.service

# Remove configuration files
rm -f /etc/gdm/custom.conf.bak
rm -f /etc/lightdm/lightdm.conf.bak
rm -f /usr/share/xsessions/kiosk-session.desktop
rm -f /etc/security/limits.d/kiosk-limits.conf

# Remove application directory
rm -rf /opt/device-monitor

# Remove kiosk user (optional - comment out if you want to keep the user)
# userdel -r kioskuser || true

# Reload systemd
systemctl daemon-reload

log "Uninstallation completed"
EOF
    
    chmod +x /opt/device-monitor/uninstall-kiosk.sh
    log "Uninstall script created at /opt/device-monitor/uninstall-kiosk.sh"
}

# Main installation function
main() {
    log "Starting Device Monitor Kiosk installation for RHEL 7.9..."
    
    check_root
    check_rhel_version
    install_packages
    create_kiosk_user
    install_application
    configure_systemd
    configure_display_manager
    configure_kiosk_session
    configure_security
    create_uninstall_script
    
    log "Installation completed successfully!"
    echo ""
    echo -e "${GREEN}Device Monitor Kiosk has been installed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Reboot the system: sudo reboot"
    echo "2. The system will automatically login as '$KIOSK_USER'"
    echo "3. The Device Monitor application will start automatically"
    echo ""
    echo "To uninstall: sudo /opt/device-monitor/uninstall-kiosk.sh"
    echo "To check service status: sudo systemctl status device-monitor-kiosk.service"
    echo "To view logs: sudo journalctl -u device-monitor-kiosk.service -f"
    echo ""
    echo -e "${YELLOW}Please reboot the system to activate kiosk mode.${NC}"
}

# Run main installation
main "$@"