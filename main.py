#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
GUARD - General USB Automated Response and Device monitoring
A Python tkinter-based GUI application for USB device monitoring and system control
Compatible with RHEL 7.9 and Windows
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import threading
import subprocess
import os
import time
import queue
import logging
from pathlib import Path
import json
import sys
import platform

# Windows-specific imports
if platform.system() == "Windows":
    try:
        import ctypes
        import winreg
        import win32gui
        import win32con
        # For hiding console windows
        CREATE_NO_WINDOW = 0x08000000
    except ImportError:
        CREATE_NO_WINDOW = 0x08000000

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("guard.log"), logging.StreamHandler()],
)
logger = logging.getLogger(__name__)




class USBMonitor:
    """USB Device Monitor with threading support"""

    def __init__(self, device_queue, control_queue):
        self.device_queue = device_queue
        self.control_queue = control_queue
        self.known_devices = {
            "4750": "1809:4750",
            "4761": "1809:4761",
            "4761_1": "1809:4761",
        }
        self.running = False
        self.paused = False
        self.monitoring_interval = 1.0
        self.monitor_thread = None
        self._lock = threading.Lock()

    def is_device_connected(self, vendor_id, product_id, device_index=1):
        """Check if a specific USB device is connected"""
        try:
            if platform.system() == "Windows":
                # Windows implementation using PowerShell
                cmd = [
                    "powershell",
                    "-Command",
                    f"Get-PnpDevice | Where-Object {{$_.InstanceId -like '*VID_{vendor_id.upper()}*PID_{product_id.upper()}*'}}",
                ]
                result = subprocess.run(
                    cmd, 
                    stdout=subprocess.PIPE, 
                    stderr=subprocess.PIPE, 
                    timeout=10,
                    creationflags=CREATE_NO_WINDOW if platform.system() == "Windows" else 0
                )
                if result.returncode == 0 and result.stdout.strip():
                    return True
                return False
            else:
                # Linux implementation using lsusb
                result = subprocess.run(
                    ["lsusb"],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    timeout=10,
                )
                if result.returncode != 0:
                    return False

                stdout_str = result.stdout.decode("utf-8", errors="ignore")
                lines = stdout_str.strip().split("\n")
                current_index = 0

                for line in lines:
                    if (
                        vendor_id.lower() in line.lower()
                        and product_id.lower() in line.lower()
                    ):
                        current_index += 1
                        if current_index == device_index:
                            return True
                return False

        except (subprocess.TimeoutExpired, subprocess.SubprocessError) as e:
            logger.error(f"USB detection error: {e}")
            return False

    def get_4761_device_paths(self):
        """Detect all USB-4761 device paths using lsusb output."""
        try:
            if platform.system() == "Windows":
                # Windows implementation
                return []
            else:
                # Linux implementation
                result = subprocess.run(
                    ["lsusb"],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    timeout=10,
                    creationflags=CREATE_NO_WINDOW if platform.system() == "Windows" else 0
                )
                if result.returncode != 0:
                    return []

                stdout_str = result.stdout.decode("utf-8", errors="ignore")
                lines = stdout_str.strip().split("\n")
                device_paths = []
                for line in lines:
                    if "ID 1809:4761" in line:
                        parts = line.split()
                        bus = parts[1]
                        device = parts[3].replace(":", "")
                        device_paths.append(f"/dev/bus/usb/{bus}/{device}")
                return device_paths
        except Exception as e:
            logger.error(f"Error detecting 4761 devices: {e}")
            return []

    def check_devices(self):
        """Check all known devices and report status, dynamically mapping 4761 cards."""
        device_status = {
            "4750": {"connected": False, "count": 0, "instances": []},
            "4761": {"connected": False, "count": 0, "instances": []},
            "4761_1": {"connected": False, "count": 0, "instances": []},
        }

        # Check 4750
        try:
            vendor_id, product_id = self.known_devices["4750"].split(":")
            connected = self.is_device_connected(vendor_id, product_id)
            if connected:
                device_status["4750"] = {
                    "connected": True,
                    "count": 1,
                    "instances": [1],
                }
        except Exception as e:
            logger.error(f"Error checking device 4750: {e}")

        # Dynamically map 4761 devices
        try:
            paths_4761 = self.get_4761_device_paths()
            for idx, path in enumerate(paths_4761):
                if idx == 0:
                    logical_name = "4761"
                elif idx == 1:
                    logical_name = "4761_1"
                else:
                    continue  # Support up to two 4761 devices

                device_status[logical_name] = {
                    "connected": True,
                    "count": 1,
                    "instances": [path],
                }
        except Exception as e:
            logger.error(f"Error checking 4761 devices: {e}")

        return device_status

    def start_monitoring(self):
        """Start the monitoring thread"""
        with self._lock:
            if self.running:
                logger.warning("Monitor is already running")
                return False

            self.running = True
            self.paused = False
            self.monitor_thread = threading.Thread(
                target=self.monitor_loop, daemon=True
            )
            self.monitor_thread.start()
            logger.info("USB Monitor started")
            return True

    def stop_monitoring(self):
        """Stop the monitoring thread"""
        with self._lock:
            if not self.running:
                return

            self.running = False

        # Send stop command to ensure quick shutdown
        try:
            self.control_queue.put("stop", timeout=1)
        except queue.Full:
            pass

        # Wait for thread to finish
        if self.monitor_thread and self.monitor_thread.is_alive():
            self.monitor_thread.join(timeout=5)
            if self.monitor_thread.is_alive():
                logger.warning("Monitor thread did not stop gracefully")

        logger.info("USB Monitor stopped")

    def pause_monitoring(self):
        """Pause monitoring without stopping the thread"""
        with self._lock:
            if self.running:
                self.paused = True
                try:
                    self.control_queue.put("pause", timeout=1)
                except queue.Full:
                    pass
                logger.info("USB Monitor paused")

    def resume_monitoring(self):
        """Resume monitoring"""
        with self._lock:
            if self.running:
                self.paused = False
                try:
                    self.control_queue.put("resume", timeout=1)
                except queue.Full:
                    pass
                logger.info("USB Monitor resumed")

    def monitor_loop(self):
        """Main monitoring loop running in separate thread"""
        logger.info("USB Monitor thread started")

        while self.running:
            try:
                # Check for control commands
                try:
                    command = self.control_queue.get_nowait()
                    if command == "stop":
                        break
                    elif command == "pause":
                        self.paused = True
                    elif command == "resume":
                        self.paused = False
                except queue.Empty:
                    pass

                # Skip device checking if paused
                if self.paused:
                    time.sleep(0.5)
                    continue

                # Check devices
                device_status = self.check_devices()

                # Send status to main thread
                try:
                    self.device_queue.put(("device_status", device_status), timeout=1)
                except queue.Full:
                    logger.warning("Device queue full, skipping update")

                time.sleep(self.monitoring_interval)

            except Exception as e:
                logger.error(f"Monitor loop error: {e}")
                try:
                    self.device_queue.put(("error", str(e)), timeout=1)
                except queue.Full:
                    pass
                time.sleep(5)  # Wait before retrying

        logger.info("USB Monitor thread stopped")

    def is_running(self):
        """Check if monitor is running"""
        with self._lock:
            return (
                self.running and self.monitor_thread and self.monitor_thread.is_alive()
            )

    def is_paused(self):
        """Check if monitor is paused"""
        with self._lock:
            return self.paused


class SystemController:
    """System control operations with proper privilege handling"""

    @staticmethod
    def check_sudo_available():
        """Check if sudo is available"""
        try:
            result = subprocess.run(
                ["which", "sudo"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=5,
                creationflags=CREATE_NO_WINDOW if platform.system() == "Windows" else 0
            )
            return result.returncode == 0
        except subprocess.SubprocessError:
            return False

    @staticmethod
    def check_password_required():
        """Check if sudo requires password"""
        try:
            result = subprocess.run(
                ["sudo", "-n", "true"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=5,
                creationflags=CREATE_NO_WINDOW if platform.system() == "Windows" else 0
            )
            return result.returncode != 0
        except subprocess.SubprocessError:
            return True

    @classmethod
    def shutdown_system(cls):
        """Shutdown the system using the best available method"""
        commands = []

        if platform.system() == "Windows":
            commands = [
                ["shutdown", "/s", "/t", "0"],
            ]
        else:  # Linux
            if cls.check_sudo_available():
                if not cls.check_password_required():
                    commands.extend(
                        [
                            ["sudo", "shutdown", "-h", "now"],
                            ["sudo", "poweroff"],
                            ["sudo", "halt", "-p"],
                        ]
                    )
                else:
                    # Try without sudo first
                    commands.extend(
                        [["shutdown", "-h", "now"], ["poweroff"], ["halt", "-p"]]
                    )
            else:
                commands.extend(
                    [["shutdown", "-h", "now"], ["poweroff"], ["halt", "-p"]]
                )

        return cls._execute_system_command(commands, "shutdown")

    @classmethod
    def restart_system(cls):
        """Restart the system using the best available method"""
        commands = []

        if platform.system() == "Windows":
            commands = [
                ["shutdown", "/r", "/t", "0"],
            ]
        else:  # Linux
            if cls.check_sudo_available():
                if not cls.check_password_required():
                    commands.extend(
                        [["sudo", "reboot"], ["sudo", "shutdown", "-r", "now"]]
                    )
                else:
                    commands.extend([["reboot"], ["shutdown", "-r", "now"]])
            else:
                commands.extend([["reboot"], ["shutdown", "-r", "now"]])

        return cls._execute_system_command(commands, "restart")

    @staticmethod
    def _execute_system_command(commands, action):
        """Execute system commands with fallbacks"""
        for cmd in commands:
            try:
                # Check if command exists (Linux only)
                if platform.system() != "Windows":
                    result = subprocess.run(
                        ["which", cmd[0]],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        timeout=5,
                        creationflags=CREATE_NO_WINDOW if platform.system() == "Windows" else 0
                    )
                    if result.returncode != 0:
                        continue

                # Create process with no console window on Windows
                creation_flags = CREATE_NO_WINDOW if platform.system() == "Windows" else 0
                subprocess.Popen(cmd, creationflags=creation_flags)
                logger.info(f"System {action} initiated with command: {' '.join(cmd)}")
                return True
            except subprocess.SubprocessError as e:
                logger.warning(f"Command {' '.join(cmd)} failed: {e}")
                continue

        logger.error(f"All {action} commands failed")
        return False




class ApplicationLauncher:
    """Handle application launching and monitoring"""

    def __init__(self):
        self.current_process = None
        self.process_monitor_thread = None
        self.is_running = False
        self.callbacks = {}
        self._lock = threading.Lock()

    def set_callback(self, event, callback):
        """Set callback for events (started, finished, error)"""
        self.callbacks[event] = callback

    def launch_application(self, executable_path):
        """Launch external application"""
        with self._lock:
            if self.is_running:
                raise RuntimeError("Another application is already running")

        if not os.path.exists(executable_path):
            raise FileNotFoundError(f"Executable not found: {executable_path}")

        if platform.system() != "Windows" and not os.access(executable_path, os.X_OK):
            raise PermissionError(f"File is not executable: {executable_path}")

        try:
            # Set working directory to executable's directory
            working_dir = os.path.dirname(os.path.abspath(executable_path))

            # Launch with appropriate method for platform
            if platform.system() == "Windows":
                self.current_process = subprocess.Popen(
                    [executable_path],
                    cwd=working_dir,
                    creationflags=CREATE_NO_WINDOW,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
            else:
                self.current_process = subprocess.Popen(
                    [executable_path],
                    cwd=working_dir,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )

            with self._lock:
                self.is_running = True

            # Start monitoring thread
            self.process_monitor_thread = threading.Thread(
                target=self._monitor_process, daemon=True
            )
            self.process_monitor_thread.start()

            if "started" in self.callbacks:
                self.callbacks["started"]()

            logger.info(f"Application launched: {executable_path}")
            return True

        except Exception as e:
            logger.error(f"Failed to launch application: {e}")
            if "error" in self.callbacks:
                self.callbacks["error"](str(e))
            return False

    def _monitor_process(self):
        """Monitor the launched process"""
        try:
            if self.current_process:
                exit_code = self.current_process.wait()

                with self._lock:
                    self.is_running = False

                if "finished" in self.callbacks and self.callbacks["finished"]:
                    self.callbacks["finished"](exit_code)

                logger.info(f"Application finished with exit code: {exit_code}")

        except Exception as e:
            logger.error(f"Process monitoring error: {e}")
            with self._lock:
                self.is_running = False
            if "error" in self.callbacks and self.callbacks["error"]:
                self.callbacks["error"](str(e))

    def terminate_application(self):
        """Terminate the running application"""
        with self._lock:
            if not self.current_process or not self.is_running:
                return True

        try:
            if platform.system() == "Windows":
                # Windows termination
                subprocess.run(
                    ["taskkill", "/F", "/PID", str(self.current_process.pid)],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    creationflags=CREATE_NO_WINDOW
                )
            else:
                # Linux termination
                self.current_process.terminate()

                # Wait for graceful termination
                try:
                    self.current_process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    # Force kill if not terminated gracefully
                    self.current_process.kill()
                    self.current_process.wait()

            with self._lock:
                self.is_running = False

            logger.info("Application terminated")
            return True

        except Exception as e:
            logger.error(f"Failed to terminate application: {e}")
            return False


class DeviceMonitorGUI:
    """Main GUI Application"""

    def __init__(self, root):
        self.root = root
        self.root.title("GUARD Application")
        self.root.geometry("800x600")
        self.root.configure(bg="#2c3e50")

        # Set window icon with PyInstaller support
        def get_resource_path(relative_path):
            """Get absolute path to resource, works for dev and for PyInstaller."""
            try:
                # PyInstaller creates a temp folder and stores path in _MEIPASS
                base_path = Path(sys._MEIPASS)
            except AttributeError:
                # Not running in PyInstaller, use normal path
                base_path = Path(__file__).parent
            return base_path / relative_path
        
        # Determine icon file based on platform
        if platform.system() == "Windows":
            icon_file = get_resource_path("assets/guard_icon.ico")
        else:
            icon_file = get_resource_path("assets/guard_icon.png")
        
        # Try to set the window icon
        if icon_file.exists():
            try:
                if platform.system() == "Windows":
                    self.root.iconbitmap(str(icon_file))
                else:
                    icon_image = tk.PhotoImage(file=str(icon_file))
                    self.root.iconphoto(True, icon_image)
                logger.info(f"Window icon set successfully: {icon_file}")
            except Exception as e:
                logger.warning(f"Failed to set window icon from {icon_file}: {e}")
        else:
            logger.warning(f"Icon file not found: {icon_file}")

        # Fullscreen by default, but can exit with Escape or F11

        # Application state
        self.root.attributes("-fullscreen", True)
        self.root.bind("<Escape>", self.toggle_fullscreen)
        self.root.bind("<F11>", self.toggle_fullscreen)
        self.selected_executable = ""
        self.device_status = {}

        # Threading components
        self.device_queue = queue.Queue()
        self.control_queue = queue.Queue()
        self.usb_monitor = USBMonitor(self.device_queue, self.control_queue)

        # Application launcher
        self.app_launcher = ApplicationLauncher()
        self.app_launcher.set_callback("started", self.on_app_started)
        self.app_launcher.set_callback("finished", self.on_app_finished)
        self.app_launcher.set_callback("error", self.on_app_error)

        # GUI setup
        self.create_widgets()
        self.start_monitoring()

        # Update loop
        self.update_device_status()

        # Cleanup on close
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)

    def toggle_fullscreen(self, event=None):
        """Toggle fullscreen mode"""
        is_fullscreen = self.root.attributes("-fullscreen")
        self.root.attributes("-fullscreen", not is_fullscreen)

    def create_widgets(self):
        """Create all GUI widgets"""
        # Main container
        main_frame = tk.Frame(self.root, bg="#2c3e50")
        main_frame.pack(fill="both", expand=True, padx=20, pady=20)

        # Title
        title_label = tk.Label(
        main_frame,
            text="GUARD Application",
            font=("Arial", 24, "bold"),
            bg="#2c3e50",
            fg="white",
        )
        title_label.pack(pady=(0, 20))

        # Device status frame
        self.create_device_frame(main_frame)

        # Control frame
        self.create_control_frame(main_frame)

        # File selection frame
        self.create_file_frame(main_frame)

        # Action buttons frame
        self.create_action_frame(main_frame)

        # System control frame
        self.create_system_frame(main_frame)

        # Status bar
        self.status_var = tk.StringVar(value="Ready")
        status_bar = tk.Label(
            main_frame,
            textvariable=self.status_var,
            relief="sunken",
            bg="#34495e",
            fg="white",
            font=("Arial", 10),
        )
        status_bar.pack(side="bottom", fill="x", pady=(10, 0))

    def create_device_frame(self, parent):
        """Create device status display frame"""
        device_frame = tk.LabelFrame(
            parent,
            text="USB Device Status",
            font=("Arial", 14, "bold"),
            bg="#34495e",
            fg="white",
            padx=10,
            pady=10,
        )
        device_frame.pack(fill="x", pady=(0, 10))

        # Device buttons
        button_frame = tk.Frame(device_frame, bg="#34495e")
        button_frame.pack(fill="x")

        self.device_buttons = {}
        devices = [
            ("4750", "Device 4750"),
            ("4761", "Device 4761"),
            ("4761_1", "Device 4761-1"),
        ]

        for i, (device_id, label) in enumerate(devices):
            btn = tk.Button(
                button_frame,
                text=label,
                font=("Arial", 12, "bold"),
                width=15,
                height=2,
                bg="#e74c3c",
                fg="white",
                relief="raised",
                bd=3,
            )
            btn.pack(side="left", padx=10, pady=5, expand=True)
            self.device_buttons[device_id] = btn

    def create_control_frame(self, parent):
        """Create monitoring control frame"""
        control_frame = tk.LabelFrame(
            parent,
            text="Monitoring Control",
            font=("Arial", 14, "bold"),
            bg="#34495e",
            fg="white",
            padx=10,
            pady=10,
        )
        control_frame.pack(fill="x", pady=(0, 10))

        # Toggle switch
        self.monitoring_var = tk.BooleanVar(value=True)
        toggle_btn = tk.Checkbutton(
            control_frame,
            text="Enable Device Monitoring",
            variable=self.monitoring_var,
            command=self.toggle_monitoring,
            font=("Arial", 12),
            bg="#34495e",
            fg="white",
            selectcolor="#27ae60",
            activebackground="#34495e",
            activeforeground="white",
        )
        toggle_btn.pack(anchor="w")


    def create_file_frame(self, parent):
        """Create file selection frame"""
        file_frame = tk.LabelFrame(
            parent,
            text="Executable Selection",
            font=("Arial", 14, "bold"),
            bg="#34495e",
            fg="white",
            padx=10,
            pady=10,
        )
        file_frame.pack(fill="x", pady=(0, 10))

        # File path display
        self.file_path_var = tk.StringVar(value="No file selected")
        file_label = tk.Label(
            file_frame,
            textvariable=self.file_path_var,
            font=("Arial", 10),
            bg="#34495e",
            fg="#ecf0f1",
            wraplength=700,
        )
        file_label.pack(fill="x", pady=(0, 5))

        # Browse buttons
        button_frame = tk.Frame(file_frame, bg="#34495e")
        button_frame.pack(fill="x")

        usb_btn = tk.Button(
            button_frame,
            text="Browse USB",
            command=self.browse_usb,
            font=("Arial", 12),
            bg="#3498db",
            fg="white",
            width=12,
            height=1,
        )
        usb_btn.pack(side="left", padx=(0, 10))

        folder_btn = tk.Button(
            button_frame,
            text="Browse Folder",
            command=self.browse_folder,
            font=("Arial", 12),
            bg="#9b59b6",
            fg="white",
            width=12,
            height=1,
        )
        folder_btn.pack(side="left")

    def create_action_frame(self, parent):
        """Create action buttons frame"""
        action_frame = tk.LabelFrame(
            parent,
            text="Application Control",
            font=("Arial", 14, "bold"),
            bg="#34495e",
            fg="white",
            padx=10,
            pady=10,
        )
        action_frame.pack(fill="x", pady=(0, 10))

        button_frame = tk.Frame(action_frame, bg="#34495e")
        button_frame.pack()

        self.launch_btn = tk.Button(
            button_frame,
            text="Launch Application",
            command=self.launch_application,
            font=("Arial", 14, "bold"),
            bg="#27ae60",
            fg="white",
            width=20,
            height=2,
        )
        self.launch_btn.pack(side="left", padx=10)

        self.terminate_btn = tk.Button(
            button_frame,
            text="Terminate App",
            command=self.terminate_application,
            font=("Arial", 14, "bold"),
            bg="#e67e22",
            fg="white",
            width=15,
            height=2,
            state="disabled",
        )
        self.terminate_btn.pack(side="left", padx=10)

    def create_system_frame(self, parent):
        """Create system control frame"""
        system_frame = tk.LabelFrame(
            parent,
            text="System Control",
            font=("Arial", 14, "bold"),
            bg="#34495e",
            fg="white",
            padx=10,
            pady=10,
        )
        system_frame.pack(fill="x", pady=(0, 10))

        button_frame = tk.Frame(system_frame, bg="#34495e")
        button_frame.pack()

        shutdown_btn = tk.Button(
            button_frame,
            text="Shutdown System",
            command=self.shutdown_system,
            font=("Arial", 12, "bold"),
            bg="#c0392b",
            fg="white",
            width=15,
            height=2,
        )
        shutdown_btn.pack(side="left", padx=10)

        restart_btn = tk.Button(
            button_frame,
            text="Restart System",
            command=self.restart_system,
            font=("Arial", 12, "bold"),
            bg="#27ae60",
            fg="white",
            width=15,
            height=2,
        )
        restart_btn.pack(side="left", padx=10)

        exit_btn = tk.Button(
            button_frame,
            text="Exit Application",
            command=self.on_closing,
            font=("Arial", 12, "bold"),
            bg="#7f8c8d",
            fg="white",
            width=15,
            height=2,
        )
        exit_btn.pack(side="left", padx=10)



    def start_monitoring(self):
        """Start USB monitoring thread"""
        try:
            success = self.usb_monitor.start_monitoring()
            if success:
                logger.info("USB monitoring thread started")
                self.status_var.set("USB monitoring started")
            else:
                logger.error("Failed to start USB monitoring")
                messagebox.showerror("Error", "Failed to start USB monitoring")
        except Exception as e:
            logger.error(f"Failed to start monitoring: {e}")
            messagebox.showerror("Error", f"Failed to start USB monitoring: {e}")

    def update_device_status(self):
        """Update device status from monitoring thread"""
        try:
            while True:
                try:
                    message_type, data = self.device_queue.get_nowait()

                    if message_type == "device_status":
                        self.device_status = data
                        self.update_device_buttons()
                    elif message_type == "error":
                        logger.error(f"Monitor error: {data}")

                except queue.Empty:
                    break

        except Exception as e:
            logger.error(f"Status update error: {e}")

        # Schedule next update
        self.root.after(500, self.update_device_status)

    def update_device_buttons(self):
        """Update device button colors based on status"""
        for device_id, button in self.device_buttons.items():
            if device_id in self.device_status:
                status = self.device_status[device_id]
                if status["connected"]:
                    button.configure(bg="#27ae60")  # Green
                    count = status["count"]
                    button.configure(text=f"Device {device_id} ({count})")
                else:
                    button.configure(bg="#e74c3c")  # Red
                    button.configure(text=f"Device {device_id}")

    def toggle_monitoring(self):
        """Toggle USB monitoring on/off"""
        if self.monitoring_var.get():
            try:
                self.usb_monitor.resume_monitoring()
                self.status_var.set("Monitoring enabled")
            except Exception as e:
                logger.error(f"Failed to resume monitoring: {e}")
        else:
            try:
                self.usb_monitor.pause_monitoring()
                self.status_var.set("Monitoring paused")
                # Reset button colors
                for button in self.device_buttons.values():
                    button.configure(bg="#7f8c8d")
            except Exception as e:
                logger.error(f"Failed to pause monitoring: {e}")

    def browse_usb(self):
        """Browse USB devices for executables"""
        if platform.system() == "Windows":
            usb_paths = ["E:", "F:", "G:", "H:", "I:", "J:"]  # Common USB drive letters
        else:
            usb_paths = ["/run/media", "/media", "/mnt"]

        for path in usb_paths:
            if os.path.exists(path):
                directory = filedialog.askdirectory(
                    title="Select USB Directory", initialdir=path
                )
                if directory:
                    self.find_executable_in_directory(directory)
                    return

        messagebox.showwarning("Warning", "No USB mount points found")

    def browse_folder(self):
        """Browse for executable files"""
        directory = filedialog.askdirectory(
            title="Select Directory Containing Executable"
        )
        if directory:
            self.find_executable_in_directory(directory)

    def find_executable_in_directory(self, directory):
        """Find executable files in directory"""
        try:
            executables = []
            for file_path in Path(directory).rglob("*"):
                if file_path.is_file():
                    # Check if file is executable based on platform
                    if platform.system() == "Windows":
                        if file_path.suffix.lower() in [".exe", ".bat", ".cmd"]:
                            executables.append(str(file_path))
                    else:
                        if os.access(file_path, os.X_OK):
                            executables.append(str(file_path))

            if not executables:
                messagebox.showwarning(
                    "Warning", "No executable files found in selected directory"
                )
                return

            if len(executables) == 1:
                self.selected_executable = executables[0]
                self.file_path_var.set(self.selected_executable)
                self.status_var.set("Executable selected successfully")
            else:
                # Show selection dialog for multiple executables
                self.show_executable_selection(executables)

        except Exception as e:
            logger.error(f"Error finding executables: {e}")
            messagebox.showerror("Error", f"Error searching for executables: {e}")

    def show_executable_selection(self, executables):
        """Show dialog to select from multiple executables"""
        selection_window = tk.Toplevel(self.root)
        selection_window.title("Select Executable")
        selection_window.geometry("600x400")
        selection_window.configure(bg="#34495e")
        selection_window.transient(self.root)
        selection_window.grab_set()

        # Center the window
        selection_window.geometry(
            "+%d+%d" % (self.root.winfo_rootx() + 50, self.root.winfo_rooty() + 50)
        )

        # Title
        title_label = tk.Label(
            selection_window,
            text="Multiple executables found. Please select one:",
            font=("Arial", 12, "bold"),
            bg="#34495e",
            fg="white",
        )
        title_label.pack(pady=10)

        # Listbox with scrollbar
        frame = tk.Frame(selection_window, bg="#34495e")
        frame.pack(fill="both", expand=True, padx=20, pady=10)

        scrollbar = tk.Scrollbar(frame)
        scrollbar.pack(side="right", fill="y")

        listbox = tk.Listbox(
            frame,
            yscrollcommand=scrollbar.set,
            font=("Arial", 10),
            bg="white",
            selectmode="single",
        )
        listbox.pack(fill="both", expand=True)
        scrollbar.config(command=listbox.yview)

        # Populate listbox
        for exe in executables:
            listbox.insert("end", os.path.basename(exe))

        # Buttons
        button_frame = tk.Frame(selection_window, bg="#34495e")
        button_frame.pack(pady=10)

        def on_select():
            selection = listbox.curselection()
            if selection:
                self.selected_executable = executables[selection[0]]
                self.file_path_var.set(self.selected_executable)
                self.status_var.set("Executable selected successfully")
                selection_window.destroy()

        def on_cancel():
            selection_window.destroy()

        select_btn = tk.Button(
            button_frame,
            text="Select",
            command=on_select,
            font=("Arial", 12),
            bg="#27ae60",
            fg="white",
            width=10,
        )
        select_btn.pack(side="left", padx=10)

        cancel_btn = tk.Button(
            button_frame,
            text="Cancel",
            command=on_cancel,
            font=("Arial", 12),
            bg="#e74c3c",
            fg="white",
            width=10,
        )
        cancel_btn.pack(side="left", padx=10)

        # Double-click to select
        listbox.bind("<Double-1>", lambda e: on_select())

    def launch_application(self):
        """Launch selected application"""
        if not self.selected_executable:
            messagebox.showwarning("Warning", "Please select an executable file first")
            return

        if self.app_launcher.is_running:
            messagebox.showwarning("Warning", "Another application is already running")
            return

        success = self.app_launcher.launch_application(self.selected_executable)
        if not success:
            messagebox.showerror("Error", "Failed to launch application")

    def terminate_application(self):
        """Terminate running application"""
        if self.app_launcher.is_running:
            success = self.app_launcher.terminate_application()
            if success:
                self.status_var.set("Application terminated")
            else:
                messagebox.showerror("Error", "Failed to terminate application")

    def on_app_started(self):
        """Callback when application starts"""
        self.launch_btn.configure(state="disabled", text="Application Running")
        self.terminate_btn.configure(state="normal")
        self.status_var.set("Application started successfully")

    def on_app_finished(self, exit_code):
        """Callback when application finishes"""
        self.launch_btn.configure(state="normal", text="Launch Application")
        self.terminate_btn.configure(state="disabled")
        if exit_code == 0:
            self.status_var.set("Application finished successfully")
        else:
            self.status_var.set(f"Application finished with exit code: {exit_code}")

    def on_app_error(self, error_msg):
        """Callback when application error occurs"""
        self.launch_btn.configure(state="normal", text="Launch Application")
        self.terminate_btn.configure(state="disabled")
        self.status_var.set(f"Application error: {error_msg}")
        messagebox.showerror("Application Error", error_msg)

    def shutdown_system(self):
        """Shutdown the system"""
        if messagebox.askyesno(
            "Confirm Shutdown", "Are you sure you want to shutdown the system?"
        ):
            success = SystemController.shutdown_system()
            if success:
                self.status_var.set("System shutdown initiated")
            else:
                messagebox.showerror("Error", "Failed to initiate system shutdown")

    def restart_system(self):
        """Restart the system"""
        if messagebox.askyesno(
            "Confirm Restart", "Are you sure you want to restart the system?"
        ):
            success = SystemController.restart_system()
            if success:
                self.status_var.set("System restart initiated")
            else:
                messagebox.showerror("Error", "Failed to initiate system restart")

    def on_closing(self):
        """Handle application closing"""
        if self.app_launcher.is_running:
            if messagebox.askyesno(
                "Confirm Exit",
                "An application is still running. Do you want to terminate it and exit?",
            ):
                self.app_launcher.terminate_application()
            else:
                return

        try:
            # Stop monitoring
            self.usb_monitor.stop_monitoring()

            logger.info("Application closing")
            self.root.quit()
            self.root.destroy()

        except Exception as e:
            logger.error(f"Error during cleanup: {e}")
            self.root.quit()


def main():
    """Main application entry point"""
    # Create and run application
    root = tk.Tk()
    app = DeviceMonitorGUI(root)

    try:
        root.mainloop()
    except KeyboardInterrupt:
        logger.info("Application interrupted by user")
    except Exception as e:
        logger.error(f"Application error: {e}")
    finally:
        # Cleanup
        try:
            if hasattr(app, "usb_monitor"):
                app.usb_monitor.stop_monitoring()
        except Exception as e:
            logger.error(f"Cleanup error: {e}")


if __name__ == "__main__":
    main()
