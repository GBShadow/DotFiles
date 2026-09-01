#!/usr/bin/env bash
# ==============================================================================
# Controle de Volume e Mudo para i3wm / PipeWire / PulseAudio
# ==============================================================================

case "$1" in
    up)
        pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null || true
        pactl set-sink-volume @DEFAULT_SINK@ +5% 2>/dev/null || true
        ;;
    down)
        pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null || true
        pactl set-sink-volume @DEFAULT_SINK@ -5% 2>/dev/null || true
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle 2>/dev/null || true
        ;;
    mic-mute)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle 2>/dev/null || true
        ;;
    *)
        echo "Uso: $0 {up|down|mute|mic-mute}"
        exit 1
        ;;
esac
