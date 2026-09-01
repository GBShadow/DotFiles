#!/usr/bin/env bash
# ==============================================================================
# Retorna o ícone e nome da saída de áudio atual para Polybar / i3status
# ==============================================================================
SINK=$(pactl get-default-sink 2>/dev/null || true)

if [[ "$SINK" == bluez_output* ]]; then
    echo "󰂯 BT"
elif [[ "$SINK" == *hdmi* ]]; then
    echo "󰍹 HDMI"
else
    echo "󰓃 Fone"
fi
