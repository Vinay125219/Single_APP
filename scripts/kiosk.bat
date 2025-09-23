@echo off
:loop
start /wait device_monitor.exe
echo "Application exited. Restarting in 5 seconds..."
timeout /t 5
goto loop
