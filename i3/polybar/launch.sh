#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar 2>/dev/null

# Wait until the processes have been shut down
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.1; done

# Pick the monitor that actually has a CRTC assigned (an output that is merely
# "connected" may be switched off, e.g. LVDS-1 here). Prefer the primary one.
pick_monitor() {
    xrandr --listactivemonitors 2>/dev/null | awk '
        /^ *[0-9]+:/ {
            if (!first) { first = $NF }
            if ($2 ~ /\*/) { primary = $NF }
        }
        END { print (primary != "" ? primary : first) }'
}

# monitors.sh may still be reconfiguring outputs; retry for up to ~10s.
for _ in $(seq 1 50); do
    MONITOR="$(pick_monitor)"
    [ -n "$MONITOR" ] && break
    sleep 0.2
done

if [ -z "$MONITOR" ]; then
    echo "launch.sh: no active monitor reported by xrandr, aborting" >>/tmp/polybar.log
    exit 1
fi
export MONITOR

# Launch Polybar in background cleanly
nohup polybar main >>/tmp/polybar.log 2>&1 &

# Wait for Polybar to initialize the tray manager
sleep 0.8

# Restart or reconnect tray applications so their tray icons properly re-dock
killall -q copyq 2>/dev/null
killall -q xfce4-clipman 2>/dev/null

sleep 0.3

if ! pgrep -u $UID -x nm-applet >/dev/null; then
    nohup nm-applet >/dev/null 2>&1 &
fi

if ! pgrep -u $UID -x blueman-applet >/dev/null; then
    nohup blueman-applet >/dev/null 2>&1 &
fi

nohup copyq >/dev/null 2>&1 &
nohup xfce4-clipman >/dev/null 2>&1 &
