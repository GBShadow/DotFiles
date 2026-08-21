#!/usr/bin/env bash
# ~/.config/niri/scripts/audio-toggle.sh
# Alterna a saída de áudio padrão entre HDMI e Alto-falantes/Fones analógicos

HDMI_SINK="alsa_output.pci-0000_00_1b.0.pro-output-3"
ANALOG_SINK="alsa_output.pci-0000_00_1b.0.pro-output-0"

CURRENT_DEFAULT=$(pactl get-default-sink 2>/dev/null)

if [ "$CURRENT_DEFAULT" = "$HDMI_SINK" ]; then
    pactl set-default-sink "$ANALOG_SINK"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Áudio" "Saída de Áudio" "Alternado para: Alto-falantes / Fones (Analógico)" -i audio-speakers
    fi
else
    pactl set-default-sink "$HDMI_SINK"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Áudio" "Saída de Áudio" "Alternado para: Monitor Externo (HDMI)" -i video-display
    fi
fi
