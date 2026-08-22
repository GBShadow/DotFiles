#!/usr/bin/env bash
# ==============================================================================
# Script para alternar entre saídas de áudio (HDMI / Analógico / Fones / USB)
# ==============================================================================

# Se houver múltiplos destinos (sinks) ativos, alterna entre eles
SINKS=($(pactl list short sinks | awk '{print $2}'))
CURRENT_SINK=$(pactl get-default-sink 2>/dev/null || true)
CARD="alsa_card.pci-0000_00_1b.0"

if [ ${#SINKS[@]} -gt 1 ]; then
    # Alterna para o próximo sink da lista
    NEXT_SINK="${SINKS[0]}"
    for i in "${!SINKS[@]}"; do
        if [ "${SINKS[$i]}" = "$CURRENT_SINK" ]; then
            NEXT_INDEX=$(( (i + 1) % ${#SINKS[@]} ))
            NEXT_SINK="${SINKS[$NEXT_INDEX]}"
            break
        fi
    done
    pactl set-default-sink "$NEXT_SINK"
else
    # Se houver apenas 1 sink no PipeWire/Pulse, alterna o perfil da placa ALC269 / HDMI
    CURRENT_PROFILE=$(pactl list cards | grep "Perfil ativo:" | head -1 | awk '{print $3}')
    
    if [[ "$CURRENT_PROFILE" == *"hdmi"* ]]; then
        pactl set-card-profile "$CARD" "output:analog-stereo+input:analog-stereo" 2>/dev/null || \
        pactl set-card-profile "$CARD" "output:analog-stereo" 2>/dev/null
    else
        pactl set-card-profile "$CARD" "output:hdmi-stereo+input:analog-stereo" 2>/dev/null || \
        pactl set-card-profile "$CARD" "output:hdmi-stereo" 2>/dev/null
    fi
fi

# Aguarda 100ms para o PipeWire atualizar o sink
sleep 0.1

# Obtém informações do destino atual para notificação
NEW_SINK=$(pactl get-default-sink 2>/dev/null || true)
NEW_DESC=$(pactl list sinks 2>/dev/null | grep -E "Descrição:|Description:" | head -1 | cut -d: -f2- | sed 's/^[ \t]*//')
[ -z "$NEW_DESC" ] && NEW_DESC="$NEW_SINK"

if [[ "$NEW_SINK" == *"hdmi"* ]] || [[ "$NEW_DESC" == *"HDMI"* ]] || [[ "$NEW_DESC" == *"Digital"* ]]; then
    ICON="video-display"
    TITLE="Áudio: HDMI / Monitor"
elif [[ "$NEW_SINK" == *"analog"* ]] || [[ "$NEW_DESC" == *"Analógico"* ]] || [[ "$NEW_DESC" == *"Stereo"* ]]; then
    ICON="audio-speakers"
    TITLE="Áudio: Alto-falantes / Fones"
else
    ICON="audio-card"
    TITLE="Áudio: $NEW_DESC"
fi

notify-send -u low -i "$ICON" -h string:x-canonical-private-synchronous:audio-toggle "$TITLE" "$NEW_DESC"
