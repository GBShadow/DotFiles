#!/usr/bin/env bash
# ==============================================================================
# game-mode.sh — alterna o notebook Celeron 1037U para modo jogo (PSX/NDS)
#
#   on      : desliga o picom (blur dual_kawase custa GPU/CPU) e fixa o
#             governor da CPU em "performance" (relógio estável no 1037U)
#   off     : volta o picom e restaura o governor original (ex: schedutil)
#   status  : mostra o estado atual
# ==============================================================================
set -e

GOVS=$(echo /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor)
STATE_FILE="${XDG_RUNTIME_DIR:-/dev/shm}/game_mode_prev_governor"

case "${1:-status}" in
    on)
        if pgrep -x picom >/dev/null 2>&1; then
            pkill -x picom 2>/dev/null || true
            while pgrep -x picom >/dev/null 2>&1; do sleep 0.05; done
            echo "✔ picom desligado (blur/composição off — sobra GPU para o emulador)"
        fi

        # Salva o governor atual antes de mudar para performance
        if [ ! -f "$STATE_FILE" ]; then
            cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor > "$STATE_FILE" 2>/dev/null || true
        fi

        for g in $GOVS; do echo performance | sudo tee "$g" >/dev/null; done
        echo "✔ CPU governor: performance (relógio estável, sem queda de frequência)"
        echo "Bom jogo! Depois: game-mode.sh off"
        ;;
    off)
        RESTORE_GOV="schedutil"
        if [ -f "$STATE_FILE" ]; then
            RESTORE_GOV="$(cat "$STATE_FILE" 2>/dev/null || echo schedutil)"
            rm -f "$STATE_FILE"
        fi
        [ -z "$RESTORE_GOV" ] && RESTORE_GOV="schedutil"

        for g in $GOVS; do echo "$RESTORE_GOV" | sudo tee "$g" >/dev/null; done
        echo "✔ CPU governor restaurado: $RESTORE_GOV"

        if [ -n "$DISPLAY" ] && command -v picom >/dev/null 2>&1 && ! pgrep -x picom >/dev/null 2>&1; then
            picom -b --config "$HOME/.config/picom/picom.conf" 2>/dev/null || true
            echo "✔ picom religado"
        fi
        ;;
    status)
        echo "governor : $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'desconhecido')"
        echo "picom    : $(pgrep -x picom >/dev/null && echo 'rodando' || echo 'desligado')"
        echo "frequência atual: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo '0') kHz"
        ;;
    *)
        echo "uso: game-mode.sh on|off|status"
        exit 1
        ;;
esac
