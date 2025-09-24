#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Windows Service Implementation for Device Monitor Kiosk
Provides auto-boot functionality for Windows systems
"""

import win32serviceutil
import win32service
import win32event
import servicemanager
import win32ts
import win32con
import win32api
import win32gui
import win32process
import socket
import sys
import os
import subprocess
import time
import logging
import threading
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("C:\\ProgramData\\DeviceMonitor\\service.log"),
        logging.StreamHandler(),
    ],
)
logger = logging.getLogger(__name__)


class DeviceMonitorKioskService(win32serviceutil.ServiceFramework):
    """Windows Service for Device Monitor Kiosk"""

    _svc_name_ = "DeviceMonitorKiosk"
    _svc_display_name_ = "Device Monitor Kiosk Service"
    _svc_description_ = (
        "Runs Device Monitor Application in Kiosk Mode on system startup"
    )
    _svc_deps_ = ["EventLog"]

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        socket.setdefaulttimeout(60)
        self.is_alive = True
        self.app_process = None
        self.monitor_thread = None

        # Configuration
        self.app_path = self._get_app_path()
        self.max_restart_attempts = 5
        self.restart_delay = 10  # seconds
        self.session_check_interval = 5  # seconds

        logger.info(f"Service initialized with app path: {self.app_path}")

    def _get_app_path(self):
        """Get application path from various sources"""
        # Try to get from service installation directory
        service_dir = os.path.dirname(os.path.abspath(__file__))

        # Look for main.py in same directory
        main_py = os.path.join(service_dir, "main.py")
        if os.path.exists(main_py):
            return main_py

        # Look for compiled executable
        exe_path = os.path.join(service_dir, "device_monitor_kiosk.exe")
        if os.path.exists(exe_path):
            return exe_path

        # Default paths
        default_paths = [
            "C:\\Program Files\\DeviceMonitor\\main.py",
            "C:\\Program Files\\DeviceMonitor\\device_monitor_kiosk.exe",
            "C:\\DeviceMonitor\\main.py",
            "C:\\DeviceMonitor\\device_monitor_kiosk.exe",
        ]

        for path in default_paths:
            if os.path.exists(path):
                return path

        # Fallback to current directory
        return os.path.join(os.getcwd(), "main.py")

    def SvcStop(self):
        """Stop the service"""
        logger.info("Service stop requested")
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)

        self.is_alive = False

        # Terminate application if running
        if self.app_process:
            try:
                self.app_process.terminate()
                self.app_process.wait(timeout=10)
            except:
                try:
                    self.app_process.kill()
                except:
                    pass

        win32event.SetEvent(self.hWaitStop)
        logger.info("Service stopped")

    def SvcDoRun(self):
        """Main service execution"""
        servicemanager.LogMsg(
            servicemanager.EVENTLOG_INFORMATION_TYPE,
            servicemanager.PYS_SERVICE_STARTED,
            (self._svc_name_, ""),
        )

        logger.info("Device Monitor Kiosk Service started")
        self.main()

    def main(self):
        """Main service loop"""
        # Start monitoring thread
        self.monitor_thread = threading.Thread(
            target=self._monitor_sessions, daemon=True
        )
        self.monitor_thread.start()

        # Wait for stop event
        win32event.WaitForSingleObject(self.hWaitStop, win32event.INFINITE)

        logger.info("Service main loop ended")

    def _monitor_sessions(self):
        """Monitor user sessions and launch application when appropriate"""
        logger.info("Session monitoring started")
        restart_count = 0

        while self.is_alive:
            try:
                # Find active user session
                active_session = self._get_active_session()

                if active_session is not None:
                    logger.info(f"Active session found: {active_session}")

                    # Check if application is running
                    if not self._is_app_running():
                        logger.info("Application not running, starting...")

                        if restart_count >= self.max_restart_attempts:
                            logger.error(
                                f"Maximum restart attempts ({self.max_restart_attempts}) reached"
                            )
                            break

                        success = self._launch_application(active_session)
                        if success:
                            restart_count = 0  # Reset counter on successful start
                        else:
                            restart_count += 1
                            logger.error(
                                f"Failed to start application (attempt {restart_count})"
                            )

                else:
                    logger.debug("No active session found")

                time.sleep(self.session_check_interval)

            except Exception as e:
                logger.error(f"Session monitoring error: {e}")
                time.sleep(self.session_check_interval * 2)

        logger.info("Session monitoring stopped")

    def _get_active_session(self):
        """Get active user session ID"""
        try:
            sessions = win32ts.WTSEnumerateSessions(win32ts.WTS_CURRENT_SERVER_HANDLE)

            for session in sessions:
                if session["State"] == win32ts.WTSActive:
                    session_id = session["SessionId"]

                    # Skip session 0 (system session)
                    if session_id == 0:
                        continue

                    # Check if session has a user logged in
                    try:
                        username = win32ts.WTSQuerySessionInformation(
                            win32ts.WTS_CURRENT_SERVER_HANDLE,
                            session_id,
                            win32ts.WTSUserName,
                        )
                        if username:
                            logger.debug(
                                f"Found active session {session_id} for user: {username}"
                            )
                            return session_id
                    except:
                        continue

            return None

        except Exception as e:
            logger.error(f"Error enumerating sessions: {e}")
            return None

    def _is_app_running(self):
        """Check if application is currently running"""
        if self.app_process is None:
            return False

        try:
            # Check if process is still alive
            exit_code = self.app_process.poll()
            if exit_code is None:
                return True  # Process is still running
            else:
                logger.info(f"Application process exited with code: {exit_code}")
                self.app_process = None
                return False
        except:
            self.app_process = None
            return False

    def _launch_application(self, session_id):
        """Launch application in specified session"""
        try:
            if not os.path.exists(self.app_path):
                logger.error(f"Application not found: {self.app_path}")
                return False

            # Prepare command
            if self.app_path.endswith(".py"):
                # Python script
                cmd = [sys.executable, self.app_path, "--kiosk"]
            else:
                # Executable
                cmd = [self.app_path, "--kiosk"]

            # Set environment variables for kiosk mode
            env = os.environ.copy()
            env["KIOSK"] = "1"

            # Launch in user session
            logger.info(
                f"Launching application in session {session_id}: {' '.join(cmd)}"
            )

            # Use subprocess to launch in current session context
            self.app_process = subprocess.Popen(
                cmd,
                env=env,
                cwd=os.path.dirname(self.app_path),
                creationflags=subprocess.CREATE_NEW_PROCESS_GROUP,
            )

            logger.info(f"Application launched with PID: {self.app_process.pid}")
            return True

        except Exception as e:
            logger.error(f"Failed to launch application: {e}")
            return False

    def _create_process_in_session(self, session_id, cmd, env):
        """Create process in specific session (advanced method)"""
        try:
            # This is a more advanced method that requires additional privileges
            # For now, we'll use the simpler subprocess method
            return subprocess.Popen(
                cmd,
                env=env,
                cwd=os.path.dirname(self.app_path),
                creationflags=subprocess.CREATE_NEW_PROCESS_GROUP,
            )
        except Exception as e:
            logger.error(f"Failed to create process in session: {e}")
            return None


def install_service():
    """Install the service"""
    try:
        # Ensure log directory exists
        log_dir = Path("C:\\ProgramData\\DeviceMonitor")
        log_dir.mkdir(parents=True, exist_ok=True)

        win32serviceutil.InstallService(
            DeviceMonitorKioskService,
            DeviceMonitorKioskService._svc_name_,
            DeviceMonitorKioskService._svc_display_name_,
            description=DeviceMonitorKioskService._svc_description_,
        )
        print("Service installed successfully")

        # Set service to start automatically
        import win32service

        hscm = win32service.OpenSCManager(
            None, None, win32service.SC_MANAGER_ALL_ACCESS
        )
        try:
            hs = win32service.OpenService(
                hscm,
                DeviceMonitorKioskService._svc_name_,
                win32service.SERVICE_ALL_ACCESS,
            )
            try:
                win32service.ChangeServiceConfig(
                    hs,
                    win32service.SERVICE_NO_CHANGE,
                    win32service.SERVICE_AUTO_START,  # Start automatically
                    win32service.SERVICE_NO_CHANGE,
                    None,
                    None,
                    None,
                    None,
                    None,
                    None,
                    None,
                )
                print("Service configured to start automatically")
            finally:
                win32service.CloseServiceHandle(hs)
        finally:
            win32service.CloseServiceHandle(hscm)

    except Exception as e:
        print(f"Failed to install service: {e}")


def uninstall_service():
    """Uninstall the service"""
    try:
        win32serviceutil.RemoveService(DeviceMonitorKioskService._svc_name_)
        print("Service uninstalled successfully")
    except Exception as e:
        print(f"Failed to uninstall service: {e}")


if __name__ == "__main__":
    if len(sys.argv) == 1:
        # Run as service
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(DeviceMonitorKioskService)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        # Handle command line arguments
        if "install" in sys.argv:
            install_service()
        elif "remove" in sys.argv or "uninstall" in sys.argv:
            uninstall_service()
        else:
            # Standard service utility commands
            win32serviceutil.HandleCommandLine(DeviceMonitorKioskService)
