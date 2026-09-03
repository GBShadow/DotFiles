#!/bin/bash
# ==============================================================================
# Toca o som de conclusão de tarefa do Oh My Pi (Ragnarok Level Up!)
# Debounce de 2 segundos para evitar sons duplicados
# ==============================================================================
LOCK="/tmp/omp_sound_last"
NOW=$(date +%s%N 2>/dev/null || date +%s000000000)

if [ -f "$LOCK" ]; then
    LAST=$(cat "$LOCK" 2>/dev/null || echo 0)
    DIFF=$(( (NOW - LAST) / 1000000 ))
    if [ "$DIFF" -ge 0 ] && [ "$DIFF" -lt 2000 ]; then
        exit 0
    fi
fi
echo "$NOW" > "$LOCK"

SOUND_FILE="/home/gbshadow/.omp/sounds/ragnarok_level_up.mp3"

if [ -f "$SOUND_FILE" ]; then
    paplay "$SOUND_FILE" 2>/dev/null || \
    mpv --no-video --really-quiet "$SOUND_FILE" 2>/dev/null &
else
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || \
    canberra-gtk-play -i complete 2>/dev/null &
fi
