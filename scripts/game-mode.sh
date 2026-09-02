#!/usr/bin/env bash
# ==============================================================================
# game-mode.sh — alterna o notebook Celeron 1037U para modo jogo (PSX/NDS)
#
#   on      : desliga o picom (blur dual_kawase custa GPU/CPU) e fixa o
#             governor da CPU em "performance" (relógio estável no 1037U)
#   off     : volta o picom e o governor para "powersave"
#   status  : mostra o estado atual
#
# Instalado em ~/.local/bin pelo i3/setup.sh. Uso:
#   game-mode.sh on && duckstation   # ou melonds
# ==============================================================================
set -e

GOVS=$(echo /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor)

case "${1:-status}" in
    on)
        if pgrep -x picom >/dev/null 2>&1; then
            pkill -x picom
            echo "✔ picom desligado (blur/composição off — sobra GPU para o emulador)"
        fi
        for g in $GOVS; do echo performance | sudo tee "$g" >/dev/null; done
        echo "✔ CPU governor: performance (relógio estável, sem queda de frequência)"
        echo "Bom jogo! Depois: game-mode.sh off"
        ;;
    off)
        for g in $GOVS; do echo powersave | sudo tee "$g" >/dev/null; done
        if [ -n "$DISPLAY" ] && command -v picom >/dev/null 2>&1 && ! pgrep -x picom >/dev/null 2>&1; then
            picom -b --config "$HOME/.config/picom/picom.conf" 2>/dev/null || true
            echo "✔ picom religado"
        fi
        echo "✔ CPU governor: powersave"
        ;;
    status)
        echo "governor : $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
        echo "picom    : $(pgrep -x picom >/dev/null && echo 'rodando' || echo 'desligado')"
        echo "frequência atual: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) kHz"
        ;;
    *)
        echo "uso: game-mode.sh on|off|status"
        exit 1
        ;;
esac
