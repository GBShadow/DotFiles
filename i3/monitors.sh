#!/bin/sh
# Detect and configure external monitor only, disable internal
# This script auto-detects the first connected external monitor and uses it as primary

INTERNAL="LVDS-1"
# Detect connected external monitor (HDMI, DP, VGA, USB)
EXTERNAL=$(xrandr --query | grep " connected" | grep -v "$INTERNAL" | head -1 | cut -d' ' -f1)

if [ -n "$EXTERNAL" ]; then
    # Disable internal, enable external with auto resolution
    xrandr --output "$INTERNAL" --off --output "$EXTERNAL" --auto --primary
else
    # No external monitor, enable internal with auto resolution (fallback)
    xrandr --output "$INTERNAL" --auto --primary
fi

# Ensure wallpaper fills the entire screen on active resolution
if [ -f "$HOME/Pictures/1375178.png" ]; then
    feh --bg-fill "$HOME/Pictures/1375178.png"
elif [ -f "$HOME/.fehbg" ]; then
    "$HOME/.fehbg"
fi
