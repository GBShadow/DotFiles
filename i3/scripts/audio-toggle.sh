#!/usr/bin/env bash
# ==============================================================================
# Alterna entre saídas de áudio: Fone (Analógico), Bluetooth (se conectado) e HDMI
# ==============================================================================

# Placa ALSA interna
ALSA_CARD=$(pactl list cards short 2>/dev/null | awk '{print $2}' | grep -E '^alsa_card' | head -n 1)
[ -z "$ALSA_CARD" ] && ALSA_CARD="alsa_card.pci-0000_00_1b.0"

# Sink Bluetooth (se houver)
BT_SINK=$(pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -E '^bluez_' | head -n 1)

# Sink atual
CURRENT_SINK=$(pactl get-default-sink 2>/dev/null || true)

# Determina estado atual: BT, HDMI ou FONE
if [[ "$CURRENT_SINK" == bluez_* ]]; then
    CURRENT_STATE="BT"
elif [[ "$CURRENT_SINK" == *hdmi* ]]; then
    CURRENT_STATE="HDMI"
else
    CURRENT_STATE="FONE"
fi

# Ciclo de alternância:
# FONE -> BT (se disponível) -> HDMI -> FONE
if [ "$CURRENT_STATE" = "FONE" ]; then
    if [ -n "$BT_SINK" ]; then
        TARGET="BT"
    else
        TARGET="HDMI"
    fi
elif [ "$CURRENT_STATE" = "BT" ]; then
    TARGET="HDMI"
elif [ "$CURRENT_STATE" = "HDMI" ]; then
    TARGET="FONE"
else
    TARGET="FONE"
fi

case "$TARGET" in
    BT)
        if [ -n "$BT_SINK" ]; then
            pactl set-default-sink "$BT_SINK"
            NEW_SINK="$BT_SINK"
            ICON="audio-headphones-bluetooth"
            TITLE="Áudio: Bluetooth"
            DEV_NAME=$(pactl list sinks 2>/dev/null | awk -v sink="$BT_SINK" '
                $0 ~ "(Nome|Name):[ \t]*" sink {found=1}
                found && ($0 ~ "device.description = " || $0 ~ "(Descrição|Description):[ \t]*") {
                    gsub(/^[ \t]*device\.description = "[ \t]*|[ \t]*(Descrição|Description):[ \t]*|"[ \t]*$/, "", $0);
                    print $0;
                    exit;
                }
            ')
            [ -z "$DEV_NAME" ] && DEV_NAME="Dispositivo Bluetooth"
            DESC="$DEV_NAME"
        fi
        ;;
    HDMI)
        pactl set-card-profile "$ALSA_CARD" "output:hdmi-stereo+input:analog-stereo" 2>/dev/null || \
        pactl set-card-profile "$ALSA_CARD" "output:hdmi-stereo" 2>/dev/null
        sleep 0.05
        HDMI_SINK=$(pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -E 'alsa_output.*hdmi-stereo' | head -n 1)
        if [ -n "$HDMI_SINK" ]; then
            pactl set-default-sink "$HDMI_SINK"
            NEW_SINK="$HDMI_SINK"
        fi
        ICON="video-display"
        TITLE="Áudio: HDMI / Monitor"
        DESC="Saída Digital HDMI"
        ;;
    FONE)
        pactl set-card-profile "$ALSA_CARD" "output:analog-stereo+input:analog-stereo" 2>/dev/null || \
        pactl set-card-profile "$ALSA_CARD" "output:analog-stereo" 2>/dev/null
        sleep 0.05
        ANALOG_SINK=$(pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -E 'alsa_output.*analog-stereo' | head -n 1)
        if [ -n "$ANALOG_SINK" ]; then
            pactl set-default-sink "$ANALOG_SINK"
            NEW_SINK="$ANALOG_SINK"
        fi
        ICON="audio-headphones"
        TITLE="Áudio: Fone / Alto-falante"
        DESC="Saída Analógica Interna"
        ;;
esac

# Move fluxos de áudio ativos para o novo destino (muda reprodução imediatamente)
if [ -n "$NEW_SINK" ]; then
    for stream in $(pactl list short sink-inputs 2>/dev/null | awk '{print $1}'); do
        pactl move-sink-input "$stream" "$NEW_SINK" 2>/dev/null || true
    done
fi

# Atualiza módulo na Polybar imediatamente se o IPC estiver ativo
polybar-msg action "#audio-out.exec" 2>/dev/null || true

# Notificação visual no desktop
notify-send -u low -i "$ICON" -h string:x-canonical-private-synchronous:audio-toggle "$TITLE" "$DESC" 2>/dev/null || true
