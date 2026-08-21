#!/usr/bin/env bash
# ~/.config/niri/scripts/brightness.sh
# Controle de brilho via software (gama) para Wayland / Niri com OSD no Noctalia

STEP="${2:-0.05}"
MIN="0.05"
MAX="1.00"
# Garante que o daemon wl-gammarelay-rs está rodando
if ! pgrep -f "wl-gammarelay-rs" >/dev/null; then
    if command -v wl-gammarelay-rs >/dev/null 2>&1; then
        wl-gammarelay-rs run &
    elif [ -x "$HOME/.cargo/bin/wl-gammarelay-rs" ]; then
        "$HOME/.cargo/bin/wl-gammarelay-rs" run &
    fi
    sleep 0.1
fi

CURRENT_VAL=$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Brightness 2>/dev/null)
CURRENT_NUM=$(awk '{ print $2 }' <<< "$CURRENT_VAL")
[ -z "$CURRENT_NUM" ] && CURRENT_NUM=1.00

case "$1" in
    up)
        NEW_VAL=$(awk -v c="$CURRENT_NUM" -v s="$STEP" -v m="$MAX" 'BEGIN { val = c + s; if (val > m) val = m; printf "%.2f", val }')
        busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Brightness d "$NEW_VAL"
        ;;
    down)
        NEW_VAL=$(awk -v c="$CURRENT_NUM" -v s="$STEP" -v min="$MIN" 'BEGIN { val = c - s; if (val < min) val = min; printf "%.2f", val }')
        busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Brightness d "$NEW_VAL"
        ;;
    set)
        NEW_VAL=$(awk -v p="$2" -v min="$MIN" -v m="$MAX" 'BEGIN { val = p / 100; if (val < min) val = min; if (val > m) val = m; printf "%.2f", val }')
        busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Brightness d "$NEW_VAL"
        ;;
    get)
        PCT=$(awk -v v="$CURRENT_NUM" 'BEGIN { print int(v * 100 + 0.5) }')
        echo "$PCT"
        exit 0
        ;;
    *)
        echo "Uso: $0 {up|down|set|get} [step/valor]"
        exit 1
        ;;
esac

# Atualiza o popup OSD do Noctalia
if [ -n "$NEW_VAL" ]; then
    PCT=$(awk -v v="$NEW_VAL" 'BEGIN { print int(v * 100 + 0.5) }')
    if command -v noctalia >/dev/null 2>&1; then
        noctalia msg brightness-osd "$PCT" >/dev/null 2>&1 &
    fi
fi
