%define _name device-monitor
%define _version 1.0.0
%define _release 1

Name:           %{_name}
Version:        %{_version}
Release:        %{_release}.el7
Summary:        Device Monitor Application
License:        Proprietary
URL:            https://github.com/astra-inc/Single

Source0:        device_monitor_rhel7

%description
A Python tkinter-based GUI application for USB device monitoring and system control.

%prep
%setup -c -T

%build
# Nothing to build, using pre-built executable

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/local/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/local/bin/%{_name}

mkdir -p %{buildroot}%{_datadir}/applications
cat <<EOF > %{buildroot}%{_datadir}/applications/%{_name}.desktop
[Desktop Entry]
Name=Device Monitor
Comment=USB Device Monitor Application
Exec=/usr/local/bin/%{_name}
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Utility;
EOF

%files
/usr/local/bin/%{_name}
%{_datadir}/applications/%{_name}.desktop

%changelog
* Thu Sep 18 2025 Gemini <gemini@google.com> - 1.0.0-1
- Initial RPM packaging.
