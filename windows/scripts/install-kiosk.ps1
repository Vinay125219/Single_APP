# Device Monitor Kiosk Installation Script for Windows
# PowerShell script for complete kiosk setup

param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Test,
    [string]$InstallPath = "C:\Program Files\DeviceMonitor",
    [string]$KioskUser = "KioskUser",
    [string]$KioskPassword = "KioskPass123!"
)

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Right-click and select 'Run as Administrator'"
    exit 1
}

Write-Host "Device Monitor Kiosk Installation for Windows" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

function Install-DeviceMonitorKiosk {
    Write-Host "Starting Device Monitor Kiosk installation..." -ForegroundColor Yellow
    
    try {
        # Step 1: Create installation directory
        Write-Host "Creating installation directory..." -ForegroundColor Blue
        if (-not (Test-Path $InstallPath)) {
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
            Write-Host "Created directory: $InstallPath" -ForegroundColor Green
        }
        
        # Step 2: Copy application files
        Write-Host "Copying application files..." -ForegroundColor Blue
        $sourceDir = Split-Path -Parent $PSScriptRoot
        
        # Copy main application
        if (Test-Path "$sourceDir\..\main.py") {
            Copy-Item "$sourceDir\..\main.py" -Destination $InstallPath -Force
            Write-Host "Copied main.py to $InstallPath" -ForegroundColor Green
        } else {
            Write-Warning "main.py not found in expected location"
        }
        
        # Copy Windows service
        if (Test-Path "$sourceDir\service\windows_service.py") {
            Copy-Item "$sourceDir\service\windows_service.py" -Destination $InstallPath -Force
            Write-Host "Copied windows_service.py to $InstallPath" -ForegroundColor Green
        }
        
        # Copy scripts
        $scriptsPath = "$InstallPath\scripts"
        if (-not (Test-Path $scriptsPath)) {
            New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
        }
        
        Copy-Item "$sourceDir\scripts\*" -Destination $scriptsPath -Recurse -Force -ErrorAction SilentlyContinue
        
        # Step 3: Install Python dependencies
        Write-Host "Installing Python dependencies..." -ForegroundColor Blue
        try {
            # Check if Python is installed
            $pythonVersion = python --version 2>$null
            if ($pythonVersion) {
                Write-Host "Python found: $pythonVersion" -ForegroundColor Green
                
                # Install required packages
                pip install --upgrade pip
                pip install pywin32  # Required for Windows service
                pip install tkinter  # GUI library
                
                Write-Host "Python dependencies installed successfully" -ForegroundColor Green
            } else {
                Write-Warning "Python not found. Please install Python 3.7+ before continuing."
                Write-Host "Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
                return $false
            }
        } catch {
            Write-Warning "Failed to install Python dependencies: $_"
        }
        
        # Step 4: Install Windows service
        Write-Host "Installing Windows service..." -ForegroundColor Blue
        try {
            Set-Location $InstallPath
            python windows_service.py install
            
            # Set service to start automatically and start it
            Set-Service -Name "DeviceMonitorKiosk" -StartupType Automatic
            Write-Host "Windows service installed and configured" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to install Windows service: $_"
        }
        
        # Step 5: Configure registry settings
        Write-Host "Configuring registry settings..." -ForegroundColor Blue
        try {
            & "$scriptsPath\configure-registry.bat"
            Write-Host "Registry settings configured" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to configure registry settings: $_"
        }
        
        # Step 6: Configure advanced kiosk settings
        Write-Host "Configuring advanced kiosk settings..." -ForegroundColor Blue
        try {
            & "$scriptsPath\configure-kiosk.ps1" -Install -KioskUser $KioskUser -KioskPassword $KioskPassword -AppPath "$InstallPath\main.py"
            Write-Host "Advanced kiosk settings configured" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to configure advanced kiosk settings: $_"
        }
        
        # Step 7: Create startup script
        Write-Host "Creating startup script..." -ForegroundColor Blue
        $startupScript = @"
@echo off
REM Device Monitor Kiosk Startup Script
cd /d "$InstallPath"
python main.py --kiosk
"@
        $startupScript | Out-File -FilePath "$InstallPath\start-kiosk.bat" -Encoding ASCII
        
        # Step 8: Create log directory
        $logDir = "C:\ProgramData\DeviceMonitor"
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            Write-Host "Created log directory: $logDir" -ForegroundColor Green
        }
        
        # Step 9: Set file permissions
        Write-Host "Setting file permissions..." -ForegroundColor Blue
        try {
            # Give kiosk user appropriate permissions
            icacls $InstallPath /grant "${KioskUser}:(OI)(CI)RX" /T
            icacls $logDir /grant "${KioskUser}:(OI)(CI)F" /T
            Write-Host "File permissions set successfully" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to set file permissions: $_"
        }
        
        # Step 10: Create uninstall script
        Write-Host "Creating uninstall script..." -ForegroundColor Blue
        $uninstallScript = @"
# Device Monitor Kiosk Uninstall Script
Write-Host "Uninstalling Device Monitor Kiosk..." -ForegroundColor Yellow

# Stop and remove service
try {
    Stop-Service -Name "DeviceMonitorKiosk" -Force -ErrorAction SilentlyContinue
    python "$InstallPath\windows_service.py" remove
    Write-Host "Service removed" -ForegroundColor Green
} catch {
    Write-Warning "Failed to remove service: `$_"
}

# Run registry restoration
try {
    & "$InstallPath\scripts\restore-registry.bat"
    Write-Host "Registry settings restored" -ForegroundColor Green
} catch {
    Write-Warning "Failed to restore registry settings: `$_"
}

# Remove kiosk configuration
try {
    & "$InstallPath\scripts\configure-kiosk.ps1" -Uninstall
    Write-Host "Kiosk configuration removed" -ForegroundColor Green
} catch {
    Write-Warning "Failed to remove kiosk configuration: `$_"
}

# Remove installation directory
try {
    Remove-Item -Path "$InstallPath" -Recurse -Force
    Write-Host "Installation directory removed" -ForegroundColor Green
} catch {
    Write-Warning "Failed to remove installation directory: `$_"
}

# Remove log directory
try {
    Remove-Item -Path "C:\ProgramData\DeviceMonitor" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Log directory removed" -ForegroundColor Green
} catch {
    # Ignore errors
}

Write-Host "Uninstallation completed!" -ForegroundColor Green
Write-Host "Please restart the system to complete the removal." -ForegroundColor Yellow
"@
        $uninstallScript | Out-File -FilePath "$InstallPath\uninstall-kiosk.ps1" -Encoding UTF8
        
        Write-Host ""
        Write-Host "Installation completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Restart the system" -ForegroundColor White
        Write-Host "2. The system will automatically login as '$KioskUser'" -ForegroundColor White
        Write-Host "3. The Device Monitor application will start automatically" -ForegroundColor White
        Write-Host ""
        Write-Host "Management commands:" -ForegroundColor Cyan
        Write-Host "  Start service:      Start-Service DeviceMonitorKiosk" -ForegroundColor White
        Write-Host "  Stop service:       Stop-Service DeviceMonitorKiosk" -ForegroundColor White
        Write-Host "  Service status:     Get-Service DeviceMonitorKiosk" -ForegroundColor White
        Write-Host "  View logs:          Get-EventLog -LogName Application -Source DeviceMonitorKiosk" -ForegroundColor White
        Write-Host "  Uninstall:          & '$InstallPath\uninstall-kiosk.ps1'" -ForegroundColor White
        Write-Host ""
        Write-Host "Emergency exit from kiosk mode: Ctrl+Alt+K" -ForegroundColor Yellow
        Write-Host ""
        
        return $true
        
    } catch {
        Write-Error "Installation failed: $_"
        return $false
    }
}

function Uninstall-DeviceMonitorKiosk {
    Write-Host "Starting Device Monitor Kiosk uninstallation..." -ForegroundColor Yellow
    
    # Run the uninstall script if it exists
    if (Test-Path "$InstallPath\uninstall-kiosk.ps1") {
        & "$InstallPath\uninstall-kiosk.ps1"
    } else {
        Write-Warning "Uninstall script not found. Performing manual cleanup..."
        
        # Manual cleanup
        try {
            Stop-Service -Name "DeviceMonitorKiosk" -Force -ErrorAction SilentlyContinue
            sc.exe delete "DeviceMonitorKiosk"
        } catch {}
        
        # Remove registry settings
        if (Test-Path "$InstallPath\scripts\restore-registry.bat") {
            & "$InstallPath\scripts\restore-registry.bat"
        }
        
        # Remove files
        if (Test-Path $InstallPath) {
            Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Write-Host "Uninstallation completed!" -ForegroundColor Green
}

function Test-DeviceMonitorKiosk {
    Write-Host "Testing Device Monitor Kiosk installation..." -ForegroundColor Blue
    Write-Host ""
    
    # Test installation directory
    if (Test-Path $InstallPath) {
        Write-Host "✓ Installation directory exists: $InstallPath" -ForegroundColor Green
    } else {
        Write-Host "✗ Installation directory not found: $InstallPath" -ForegroundColor Red
    }
    
    # Test main application
    if (Test-Path "$InstallPath\main.py") {
        Write-Host "✓ Main application found: main.py" -ForegroundColor Green
    } else {
        Write-Host "✗ Main application not found: main.py" -ForegroundColor Red
    }
    
    # Test Windows service
    try {
        $service = Get-Service -Name "DeviceMonitorKiosk" -ErrorAction SilentlyContinue
        if ($service) {
            Write-Host "✓ Windows service exists: $($service.Status)" -ForegroundColor Green
        } else {
            Write-Host "✗ Windows service not found" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Error checking Windows service: $_" -ForegroundColor Red
    }
    
    # Test Python
    try {
        $pythonVersion = python --version 2>$null
        if ($pythonVersion) {
            Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
        } else {
            Write-Host "✗ Python not found" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Python not found" -ForegroundColor Red
    }
    
    # Test kiosk user
    try {
        $user = Get-LocalUser -Name $KioskUser -ErrorAction SilentlyContinue
        if ($user) {
            Write-Host "✓ Kiosk user exists: $KioskUser" -ForegroundColor Green
        } else {
            Write-Host "✗ Kiosk user not found: $KioskUser" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Error checking kiosk user: $_" -ForegroundColor Red
    }
    
    # Test auto-login registry setting
    try {
        $autoLogin = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -ErrorAction SilentlyContinue
        if ($autoLogin.AutoAdminLogon -eq "1") {
            Write-Host "✓ Auto-login is configured" -ForegroundColor Green
        } else {
            Write-Host "✗ Auto-login not configured" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Error checking auto-login configuration" -ForegroundColor Red
    }
    
    # Test log directory
    if (Test-Path "C:\ProgramData\DeviceMonitor") {
        Write-Host "✓ Log directory exists" -ForegroundColor Green
    } else {
        Write-Host "- Log directory not found (will be created on first run)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Test completed!" -ForegroundColor Blue
}

function Show-Usage {
    Write-Host "Device Monitor Kiosk Installation Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  Install:           .\install-kiosk.ps1 -Install" -ForegroundColor Gray
    Write-Host "  Uninstall:         .\install-kiosk.ps1 -Uninstall" -ForegroundColor Gray
    Write-Host "  Test installation: .\install-kiosk.ps1 -Test" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor White
    Write-Host "  -InstallPath       Installation directory (default: C:\Program Files\DeviceMonitor)" -ForegroundColor Gray
    Write-Host "  -KioskUser         Kiosk username (default: KioskUser)" -ForegroundColor Gray
    Write-Host "  -KioskPassword     Kiosk password (default: KioskPass123!)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\install-kiosk.ps1 -Install -InstallPath 'C:\DeviceMonitor'" -ForegroundColor Gray
    Write-Host "  .\install-kiosk.ps1 -Install -KioskUser 'MyKioskUser' -KioskPassword 'MyPassword'" -ForegroundColor Gray
}

# Main execution
if ($Install) {
    $success = Install-DeviceMonitorKiosk
    if (-not $success) {
        exit 1
    }
} elseif ($Uninstall) {
    Uninstall-DeviceMonitorKiosk
} elseif ($Test) {
    Test-DeviceMonitorKiosk
} else {
    Show-Usage
}