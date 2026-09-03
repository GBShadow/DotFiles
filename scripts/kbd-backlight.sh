#!/bin/sh
# ==============================================================================
# Keyboard Backlight Controller (Scroll Lock LED)
# ==============================================================================
case "$1" in
    on)
        xset led named "Scroll Lock" 2>/dev/null || xset led 3 2>/dev/null || true
        ;;
    off)
        xset -led named "Scroll Lock" 2>/dev/null || xset -led 3 2>/dev/null || true
        ;;
    toggle|"")
        if xset q | grep -q "Scroll Lock: on"; then
            xset -led named "Scroll Lock" 2>/dev/null || xset -led 3 2>/dev/null || true
        else
            xset led named "Scroll Lock" 2>/dev/null || xset led 3 2>/dev/null || true
        fi
        ;;
esac
