#!/usr/bin/env bash

# Terminate already running bar instances
killall -9 polybar 2>/dev/null
killall -q polybar 2>/dev/null

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

# Detect primary / active monitor
PRIMARY_MONITOR=$(xrandr --query | grep " connected" | grep "primary" | cut -d" " -f1)
if [ -z "$PRIMARY_MONITOR" ]; then
    PRIMARY_MONITOR=$(xrandr --query | grep " connected" | head -1 | cut -d" " -f1)
fi
export MONITOR="$PRIMARY_MONITOR"

# Launch Polybar in background cleanly
nohup polybar main >> /tmp/polybar.log 2>&1 &

# Wait for Polybar to initialize the tray manager
sleep 0.8

# Start or reconnect tray applications
if ! pgrep -u $UID -x nm-applet >/dev/null; then
    nohup nm-applet >/dev/null 2>&1 &
fi

if ! pgrep -u $UID -x copyq >/dev/null; then
    nohup copyq >/dev/null 2>&1 &
fi
