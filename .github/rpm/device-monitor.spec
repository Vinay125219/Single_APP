%define _name guard
%define _version 1.0.0
%define _release 1

Name:           %{_name}
Version:        %{_version}
Release:        %{_release}.el7
Summary:        GUARD - General USB Automated Response and Device monitoring
License:        MIT
URL:            https://github.com/guard/guard
Source0:        guard_rhel7

%description
GUARD is a Python tkinter-based GUI application for USB device monitoring and system control.
It supports both normal mode and kiosk mode for secure environments.

%prep
%setup -c -T

%build
# Nothing to build, using pre-built executable

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/local/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/local/bin/%{_name}

# Create icon directory
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps
install -m 0644 assets/guard_icon.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/guard.png

# Create desktop entry
mkdir -p %{buildroot}%{_datadir}/applications
cat <<EOF > %{buildroot}%{_datadir}/applications/%{_name}.desktop
[Desktop Entry]
Name=GUARD
Comment=General USB Automated Response and Device monitoring
Exec=/usr/local/bin/%{_name}
Icon=guard
Terminal=false
Type=Application
Categories=Utility;
EOF

# Create kiosk mode desktop entry
cat <<EOF > %{buildroot}%{_datadir}/applications/%{_name}-kiosk.desktop
[Desktop Entry]
Name=GUARD Kiosk Mode
Comment=GUARD in Kiosk Mode
Exec=/usr/local/bin/%{_name} --kiosk
Icon=guard
Terminal=false
Type=Application
Categories=Utility;
X-GNOME-Autostart-enabled=true
EOF

# Create autostart directory and kiosk mode entry
mkdir -p %{buildroot}/etc/xdg/autostart
cat <<EOF > %{buildroot}/etc/xdg/autostart/%{_name}-kiosk.desktop
[Desktop Entry]
Name=GUARD Kiosk Mode
Comment=GUARD in Kiosk Mode
Exec=/usr/local/bin/%{_name} --kiosk
Icon=guard
Terminal=false
Type=Application
Categories=Utility;
X-GNOME-Autostart-enabled=true
EOF

%files
/usr/local/bin/%{_name}
/usr/share/icons/hicolor/256x256/apps/guard.png
%{_datadir}/applications/%{_name}.desktop
%{_datadir}/applications/%{_name}-kiosk.desktop
/etc/xdg/autostart/%{_name}-kiosk.desktop

%changelog
* Thu Sep 18 2025 GUARD Team <guard@example.com> - 1.0.0-1
- Initial RPM packaging with kiosk mode support.