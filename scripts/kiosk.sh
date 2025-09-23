#!/bin/bash
while true; do
  ./device_monitor
  echo "Application exited. Restarting in 5 seconds..."
  sleep 5
done
