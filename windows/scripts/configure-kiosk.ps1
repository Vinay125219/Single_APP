# Windows Kiosk Mode Configuration and Group Policy Scripts
# PowerShell script for advanced kiosk configuration

param(
    [switch]$Install,
    [switch]$Uninstall,
    [string]$KioskUser = "KioskUser",
    [string]$KioskPassword = "KioskPass123!",
    [string]$AppPath = "C:\Program Files\DeviceMonitor\main.py"
)

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Right-click and select 'Run as Administrator'"
    exit 1
}

Write-Host "Device Monitor Kiosk Configuration" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

function Install-KioskMode {
    Write-Host "Installing kiosk mode configuration..." -ForegroundColor Yellow
    
    # Create kiosk user if it doesn't exist
    try {
        $user = Get-LocalUser -Name $KioskUser -ErrorAction SilentlyContinue
        if (-not $user) {
            Write-Host "Creating kiosk user: $KioskUser" -ForegroundColor Blue
            $securePassword = ConvertTo-SecureString $KioskPassword -AsPlainText -Force
            New-LocalUser -Name $KioskUser -Password $securePassword -Description "Device Monitor Kiosk User Account" -PasswordNeverExpires -UserMayNotChangePassword
            Add-LocalGroupMember -Group "Users" -Member $KioskUser
            Write-Host "Kiosk user created successfully" -ForegroundColor Green
        } else {
            Write-Host "Kiosk user already exists" -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Failed to create kiosk user: $_"
        return $false
    }
    
    # Configure Windows 10/11 Assigned Access (if available)
    if ((Get-WindowsEdition).Edition -match "Pro|Enterprise|Education") {
        Write-Host "Configuring Windows Assigned Access..." -ForegroundColor Blue
        
        # Create assigned access configuration XML
        $kioskConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<AssignedAccessConfiguration xmlns="http://schemas.microsoft.com/AssignedAccess/2017/config">
    <Profiles>
        <Profile Id="{12345678-1234-1234-1234-123456789012}">
            <AllAppsList>
                <AllowedApps>
                    <App DesktopAppPath="$AppPath" />
                    <App AppUserModelId="Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" />
                </AllowedApps>
            </AllAppsList>
            <StartLayout>
                <![CDATA[<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
                  <DefaultLayoutOverride>
                    <StartLayoutCollection>
                      <defaultlayout:StartLayout GroupCellWidth="6">
                        <start:Group Name="Kiosk">
                          <start:DesktopApplicationTile Size="4x4" Column="0" Row="0" DesktopApplicationID="DeviceMonitor" />
                        </start:Group>
                      </defaultlayout:StartLayout>
                    </StartLayoutCollection>
                  </DefaultLayoutOverride>
                </LayoutModificationTemplate>]]>
            </StartLayout>
            <Taskbar ShowTaskbar="false"/>
        </Profile>
    </Profiles>
    <Configs>
        <Config>
            <Account>$KioskUser</Account>
            <DefaultProfile Id="{12345678-1234-1234-1234-123456789012}"/>
        </Config>
    </Configs>
</AssignedAccessConfiguration>
"@
        
        try {
            $configPath = "$env:TEMP\kiosk-config.xml"
            $kioskConfig | Out-File -FilePath $configPath -Encoding UTF8
            Set-AssignedAccess -ConfigurationXml (Get-Content $configPath -Raw)
            Write-Host "Assigned Access configured successfully" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to configure Assigned Access: $_"
            Write-Host "Continuing with registry-based configuration..." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Windows edition does not support Assigned Access. Using registry configuration." -ForegroundColor Yellow
    }
    
    # Configure Group Policy settings via registry
    Write-Host "Configuring Group Policy settings..." -ForegroundColor Blue
    
    # User-specific kiosk restrictions
    $userSID = (New-Object System.Security.Principal.NTAccount($KioskUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $userRegPath = "HKU:\$userSID"
    
    # Load user registry hive if not already loaded
    try {
        if (-not (Test-Path $userRegPath)) {
            reg load "HKU\$userSID" "C:\Users\$KioskUser\NTUSER.DAT"
        }
        
        # Disable various user interface elements
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDesktop" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoFind" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoRun" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoLogOff" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoClose" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoControlPanel" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoSetTaskbar" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoTrayContextMenu" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoViewContextMenu" -Value 1 -Type DWORD
        
        # Disable system access
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableTaskMgr" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableRegistryTools" -Value 1 -Type DWORD
        Set-RegistryValue -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableCMD" -Value 2 -Type DWORD
        
        Write-Host "User-specific Group Policy settings configured" -ForegroundColor Green
        
    } catch {
        Write-Warning "Failed to configure user-specific settings: $_"
    }
    
    # System-wide kiosk settings (already handled by registry script)
    Write-Host "Applying system-wide kiosk settings..." -ForegroundColor Blue
    
    # Hide cursor after inactivity
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableCursorSuppression" -Value 1 -Type DWORD
    
    # Disable Windows Store
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "RemoveWindowsStore" -Value 1 -Type DWORD
    
    # Disable Cortana
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWORD
    
    # Disable Windows Update automatic restart
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWORD
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Value 0 -Type DWORD
    
    Write-Host "Kiosk mode installation completed successfully!" -ForegroundColor Green
    return $true
}

function Uninstall-KioskMode {
    Write-Host "Uninstalling kiosk mode configuration..." -ForegroundColor Yellow
    
    # Remove Assigned Access configuration
    try {
        Clear-AssignedAccess
        Write-Host "Assigned Access configuration removed" -ForegroundColor Green
    } catch {
        Write-Host "No Assigned Access configuration to remove" -ForegroundColor Yellow
    }
    
    # Remove user-specific Group Policy settings
    $userSID = (New-Object System.Security.Principal.NTAccount($KioskUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $userRegPath = "HKU:\$userSID"
    
    try {
        if (Test-Path $userRegPath) {
            Remove-Item -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$userRegPath\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "User-specific settings removed" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to remove user-specific settings: $_"
    }
    
    # Remove system-wide settings
    Remove-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableCursorSuppression"
    Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "RemoveWindowsStore"
    Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana"
    Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers"
    Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement"
    
    Write-Host "Kiosk mode uninstallation completed!" -ForegroundColor Green
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWORD"
    )
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
        Write-Host "Set registry value: $Path\$Name = $Value" -ForegroundColor Gray
    } catch {
        Write-Warning "Failed to set registry value $Path\$Name : $_"
    }
}

function Remove-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    
    try {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        Write-Host "Removed registry value: $Path\$Name" -ForegroundColor Gray
    } catch {
        # Ignore errors when removing non-existent values
    }
}

function Test-KioskConfiguration {
    Write-Host "Testing kiosk configuration..." -ForegroundColor Blue
    
    # Check if kiosk user exists
    $user = Get-LocalUser -Name $KioskUser -ErrorAction SilentlyContinue
    if ($user) {
        Write-Host "✓ Kiosk user exists: $KioskUser" -ForegroundColor Green
    } else {
        Write-Host "✗ Kiosk user not found: $KioskUser" -ForegroundColor Red
    }
    
    # Check if application exists
    if (Test-Path $AppPath) {
        Write-Host "✓ Application found: $AppPath" -ForegroundColor Green
    } else {
        Write-Host "✗ Application not found: $AppPath" -ForegroundColor Red
    }
    
    # Check Assigned Access
    try {
        $assignedAccess = Get-AssignedAccess
        if ($assignedAccess) {
            Write-Host "✓ Assigned Access is configured" -ForegroundColor Green
        } else {
            Write-Host "- Assigned Access not configured (using registry mode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "- Assigned Access not available" -ForegroundColor Yellow
    }
    
    # Check registry settings (sample)
    $registryTests = @(
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"; Name = "AutoAdminLogon"; Expected = "1" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"; Name = "DefaultUserName"; Expected = $KioskUser }
    )
    
    foreach ($test in $registryTests) {
        try {
            $value = Get-ItemProperty -Path $test.Path -Name $test.Name -ErrorAction SilentlyContinue
            if ($value.($test.Name) -eq $test.Expected) {
                Write-Host "✓ Registry setting correct: $($test.Path)\$($test.Name)" -ForegroundColor Green
            } else {
                Write-Host "✗ Registry setting incorrect: $($test.Path)\$($test.Name)" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Registry setting missing: $($test.Path)\$($test.Name)" -ForegroundColor Red
        }
    }
}

# Main execution
if ($Install) {
    $success = Install-KioskMode
    if ($success) {
        Write-Host ""
        Write-Host "Installation completed successfully!" -ForegroundColor Green
        Write-Host "Please restart the system to activate kiosk mode." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To test the configuration: .\configure-kiosk.ps1 -Test" -ForegroundColor Cyan
        Write-Host "To uninstall: .\configure-kiosk.ps1 -Uninstall" -ForegroundColor Cyan
    }
} elseif ($Uninstall) {
    Uninstall-KioskMode
    Write-Host ""
    Write-Host "Uninstallation completed!" -ForegroundColor Green
    Write-Host "You may need to restart the system for all changes to take effect." -ForegroundColor Yellow
} else {
    # Default action is to test
    Test-KioskConfiguration
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  Install kiosk mode:   .\configure-kiosk.ps1 -Install" -ForegroundColor White
    Write-Host "  Uninstall kiosk mode: .\configure-kiosk.ps1 -Uninstall" -ForegroundColor White
    Write-Host "  Test configuration:   .\configure-kiosk.ps1" -ForegroundColor White
}