#!/bin/sh
# ==============================================================================
# Keyboard Backlight Controller — retroiluminação via LED de Scroll Lock
# ------------------------------------------------------------------------------
# Muitos teclados USB genéricos não expõem controle de iluminação próprio: a
# luz é ligada/desligada pelo LED de Scroll Lock (única saída HID do teclado).
# Este script controla essa luz de forma portátil, funcionando em:
#
#   - X11   (i3)            -> via sysfs e/ou `xset`
#   - Wayland (KWin/Plasma) -> via sysfs (xset não funciona)
#   - Wayland (Niri)        -> via sysfs
#
# Estratégia:
#   1) sysfs : /sys/class/leds/<teclado>::scrolllock/brightness  (X11 + Wayland)
#   2) xset  : fallback para X11 quando não há acesso de escrita ao sysfs
#
# Para usar sem root instale a regra udev scripts/udev/90-kbd-backlight.rules
# (o instalador kde/setup.sh faz isso automaticamente).
#
# Uso:
#   kbd-backlight.sh [on|off|toggle|status]
#
# Variáveis:
#   KBD_BACKLIGHT_LED   força o LED a ser usado, ex.:
#                       KBD_BACKLIGHT_LED=/sys/class/leds/input37::scrolllock
# ==============================================================================

set -u

# --- Detecção do LED ----------------------------------------------------------
# Prefere o LED de Scroll Lock de um teclado USB; ignora o teclado PS/2 interno
# do notebook (AT Translated Set 2 keyboard) e dispositivos de vídeo.
find_led() {
    if [ -n "${KBD_BACKLIGHT_LED:-}" ]; then
        printf '%s\n' "$KBD_BACKLIGHT_LED"
        return 0
    fi

    # 1ª escolha: LED de scroll lock cujo caminho físico está em um barramento USB
    for led in /sys/class/leds/*::scrolllock; do
        [ -e "$led/brightness" ] || continue
        dev="$(readlink -f "$led/device" 2>/dev/null || true)"
        case "$dev" in
            *usb*) printf '%s\n' "$led"; return 0 ;;
        esac
    done

    # 2ª escolha: qualquer scroll lock que não seja o teclado PS/2 interno
    for led in /sys/class/leds/*::scrolllock; do
        [ -e "$led/brightness" ] || continue
        name="$(cat "$led/device/name" 2>/dev/null || true)"
        case "$name" in
            *"AT Translated"*|*"Video Bus"*) continue ;;
        esac
        printf '%s\n' "$led"; return 0
    done

    # 3ª escolha: primeiro scroll lock disponível
    for led in /sys/class/leds/*::scrolllock; do
        [ -e "$led/brightness" ] && { printf '%s\n' "$led"; return 0; }
    done

    return 1
}

LED="$(find_led || true)"

# --- sysfs --------------------------------------------------------------------
sysfs_set() {
    # $1 = LED, $2 = 0|1 — falha silenciosamente se não houver permissão
    [ -n "$1" ] || return 1
    [ -w "$1/brightness" ] || return 1
    (printf '%s' "$2" > "$1/brightness") 2>/dev/null
}

sysfs_get() {
    [ -n "$1" ] && [ -r "$1/brightness" ] || return 1
    cat "$1/brightness" 2>/dev/null
}

# --- xset (fallback apenas em X11 nativo) -------------------------------------
# Importante: em sessões Wayland existe um XWayland em DISPLAY=:0, e o `xset`
# "tem sucesso" contra ele sem alterar o hardware. Por isso só usamos xset
# quando a sessão é realmente X11.
is_x11() {
    case "${XDG_SESSION_TYPE:-}" in
        x11)     return 0 ;;
        wayland) return 1 ;;
    esac
    [ -n "${WAYLAND_DISPLAY:-}" ] && return 1
    [ -n "${DISPLAY:-}" ] && return 0
    return 1
}

xset_set() {
    is_x11 || return 1
    command -v xset >/dev/null 2>&1 || return 1
    if [ "$1" = "1" ]; then
        xset led named "Scroll Lock" 2>/dev/null || xset led 3 2>/dev/null
    else
        xset -led named "Scroll Lock" 2>/dev/null || xset -led 3 2>/dev/null
    fi
}

xset_get() {
    is_x11 || return 1
    command -v xset >/dev/null 2>&1 || return 1
    xset q 2>/dev/null | grep -qi "Scroll Lock:[[:space:]]*on"
}

# --- Lógica -------------------------------------------------------------------
current_state() {
    v="$(sysfs_get "$LED" || true)"
    if [ "$v" = "1" ]; then
        echo on; return 0
    elif [ "$v" = "0" ]; then
        echo off; return 0
    fi
    if xset_get; then echo on; else echo off; fi
}

apply() {
    # $1 = 1|0 ; tenta sysfs primeiro, depois xset
    sysfs_set "$LED" "$1" && return 0
    xset_set "$1"
}

case "${1:-toggle}" in
    on)     apply 1 ;;
    off)    apply 0 ;;
    toggle) if [ "$(current_state)" = "on" ]; then apply 0; else apply 1; fi ;;
    status) current_state ;;
    *)      echo "Uso: $0 [on|off|toggle|status]" >&2; exit 2 ;;
esac
