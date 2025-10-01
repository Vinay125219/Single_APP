; GUARD - General USB Automated Response and Device monitoring
; Windows Installer Script

!define APP_NAME "GUARD"
!define APP_VERSION "1.0.0"
!define APP_PUBLISHER "GUARD Team"
!define APP_URL "https://github.com/guard/guard"
!define APP_EXE "guard.exe"
!define APP_DIR "GUARD"

; NSIS Settings
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"

; General
Name "${APP_NAME} ${APP_VERSION}"
OutFile "dist\guard-setup.exe"
InstallDir "$PROGRAMFILES\${APP_DIR}"
InstallDirRegKey HKCU "Software\${APP_DIR}" ""
RequestExecutionLevel admin

; Interface Settings
!define MUI_ABORTWARNING
!define MUI_ICON "assets\guard_icon.ico"
!define MUI_UNICON "assets\guard_icon.ico"

; Installer Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstaller Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

; Installer Sections
Section "GUARD" SEC01
  SetOutPath "$INSTDIR"
  
  ; Add files
  File "dist\guard.exe"
  File "assets\guard_icon.ico"
  File "README.md"
  File "LICENSE"
  
  ; Create start menu shortcut
  CreateDirectory "$SMPROGRAMS\${APP_DIR}"
  CreateShortCut "$SMPROGRAMS\${APP_DIR}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\guard_icon.ico"
  CreateShortCut "$SMPROGRAMS\${APP_DIR}\Uninstall.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
  
  ; Create desktop shortcut
  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\guard_icon.ico"
  
  ; Store installation folder
  WriteRegStr HKCU "Software\${APP_DIR}" "" $INSTDIR
  
  ; Register uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Register application in Add/Remove Programs
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_DIR}" \
                   "DisplayName" "${APP_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_DIR}" \
                   "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_DIR}" \
                   "DisplayIcon" "$INSTDIR\guard_icon.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_DIR}" \
                   "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_DIR}" \
                   "URLInfoAbout" "${APP_URL}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_DIR}" \
                   "DisplayVersion" "${APP_VERSION}"
SectionEnd

; Kiosk Mode Section
Section "Kiosk Mode" SEC02
  ; Add kiosk mode registry entries
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Policies\System" \
                   "DisableTaskMgr" "1"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" \
                   "Shell" "$INSTDIR\${APP_EXE} --kiosk"
  
  ; Create kiosk mode shortcut
  CreateShortCut "$SMPROGRAMS\${APP_DIR}\${APP_NAME} Kiosk Mode.lnk" "$INSTDIR\${APP_EXE}" "--kiosk" "$INSTDIR\guard_icon.ico"
SectionEnd

; Desktop Shortcut Section
Section "Desktop Shortcut" SEC03
  ; Create desktop shortcut
  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\guard_icon.ico"
SectionEnd

; Start Menu Shortcut Section
Section "Start Menu Shortcut" SEC04
  ; Create start menu shortcut
  CreateShortCut "$SMPROGRAMS\${APP_DIR}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\guard_icon.ico"
SectionEnd

; Uninstaller Section
Section "Uninstall"
  ; Remove registry keys
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_DIR}"
  DeleteRegKey HKCU "Software\${APP_DIR}"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Policies\System" "DisableTaskMgr"
  DeleteRegValue HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "Shell"
  
  ; Remove files
  Delete "$INSTDIR\${APP_EXE}"
  Delete "$INSTDIR\guard_icon.ico"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\Uninstall.exe"
  
  ; Remove shortcuts
  Delete "$SMPROGRAMS\${APP_DIR}\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_DIR}\${APP_NAME} Kiosk Mode.lnk"
  Delete "$SMPROGRAMS\${APP_DIR}\Uninstall.lnk"
  Delete "$DESKTOP\${APP_NAME}.lnk"
  
  ; Remove directories
  RMDir "$SMPROGRAMS\${APP_DIR}"
  RMDir "$INSTDIR"
SectionEnd

; Section Descriptions
LangString DESC_SEC01 ${LANG_ENGLISH} "Install GUARD application"
LangString DESC_SEC02 ${LANG_ENGLISH} "Enable kiosk mode (locks down system to only run GUARD)"
LangString DESC_SEC03 ${LANG_ENGLISH} "Create desktop shortcut"
LangString DESC_SEC04 ${LANG_ENGLISH} "Create start menu shortcut"

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${SEC01} $(DESC_SEC01)
!insertmacro MUI_DESCRIPTION_TEXT ${SEC02} $(DESC_SEC02)
!insertmacro MUI_DESCRIPTION_TEXT ${SEC03} $(DESC_SEC03)
!insertmacro MUI_DESCRIPTION_TEXT ${SEC04} $(DESC_SEC04)
!insertmacro MUI_FUNCTION_DESCRIPTION_END