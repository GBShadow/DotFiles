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
# PROBLEMA CONHECIDO (KWin/Wayland)
#   O KWin reescreve TODOS os LEDs do teclado (evdev_write -> EV_LED) a cada
#   mudança de Caps Lock/Num Lock, e sempre envia o bit de Scroll Lock como 0.
#   Resultado: a luz apaga ao apertar Caps/Num Lock e não volta.
#   Ver: `kwin_wayland` gravando EV_LED em /dev/input/eventN (código 2 = SCROLLL).
#   Por isso existe o modo `keep`: ele reafirma o estado desejado continuamente,
#   desfazendo a sobrescrita do compositor (e também a do console/VT).
#
# Estratégia:
#   1) sysfs : /sys/class/leds/<teclado>::scrolllock/brightness  (X11 + Wayland)
#   2) xset  : fallback para X11 quando não há acesso de escrita ao sysfs
#
# Para usar sem root instale a regra udev scripts/udev/90-kbd-backlight.rules
# (o instalador kde/setup.sh faz isso automaticamente).
#
# Uso:
#   kbd-backlight.sh [on|off|toggle|status|keep]
#
#   keep  -> modo serviço: mantém o estado desejado (usado no login)
#
# Variáveis:
#   KBD_BACKLIGHT_LED    força o LED a ser usado, ex.:
#                        KBD_BACKLIGHT_LED=/sys/class/leds/input37::scrolllock
#   KBD_BACKLIGHT_POLL   intervalo do modo keep em segundos (padrão: 0.2)
#   KBD_BACKLIGHT_STATE  caminho do arquivo de estado (padrão: XDG_RUNTIME_DIR)
# ==============================================================================

set -u

POLL="${KBD_BACKLIGHT_POLL:-0.2}"
STATE_FILE="${KBD_BACKLIGHT_STATE:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/kbd-backlight.state}"

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

# --- Estado desejado ----------------------------------------------------------
# Sem arquivo de estado o padrão é LIGADO.
state_get() {
    v=""
    if [ -r "$STATE_FILE" ]; then
        read -r v < "$STATE_FILE" 2>/dev/null || true
    fi
    case "${v:-}" in
        0|off) printf '0\n' ;;
        *)     printf '1\n' ;;
    esac
}

state_set() {
    printf '%s\n' "$1" > "$STATE_FILE" 2>/dev/null || true
}

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

# --- Trigger do console (VT) --------------------------------------------------
# O LED nasce preso ao trigger "kbd-scrolllock", que o console reescreve conforme
# o estado do Scroll Lock do VT (e de novo a cada teclado conectado). Soltamos o
# trigger para que só o nosso valor controle o LED. Requer a regra udev.
detach_trigger() {
    [ -n "${1:-}" ] || return 0
    t="$1/trigger"
    [ -w "$t" ] || return 0
    read -r cur < "$t" 2>/dev/null || return 0
    case "$cur" in
        *"[none]"*) ;;
        *) printf 'none' > "$t" 2>/dev/null || true ;;
    esac
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
    detach_trigger "$LED"
    if sysfs_set "$LED" "$1"; then
        state_set "$1"
        return 0
    fi
    if xset_set "$1"; then
        state_set "$1"
        return 0
    fi
    return 1
}

# Modo serviço: mantém o LED no estado desejado, desfazendo sobrescritas do
# compositor (KWin) e do console. Também re-detecta o LED se o teclado for
# reconectado (o nome inputNN::scrolllock muda).
keep() {
    n=0
    while :; do
        n=$((n + 1))

        # Re-detecta o LED:
        #   - imediatamente se ele sumiu (teclado reconectado); e
        #   - de tempo em tempo, para corrigir uma detecção de fallback.
        # Sem a re-detecção periódica, durante a re-enumeração do teclado USB o
        # `find_led` pode cair no LED do teclado PS/2 interno (AT Translated) e
        # ficar preso nele para sempre, deixando a luz apagada.
        if [ -z "$LED" ] || [ ! -e "$LED/brightness" ]; then
            LED="$(find_led || true)"
        elif [ $((n % 5)) -eq 0 ]; then
            new="$(find_led || true)"
            [ -n "$new" ] && LED="$new"
        fi

        if [ -n "$LED" ]; then
            detach_trigger "$LED"

            # estado desejado (sem subshell: leitura direta)
            want=1
            if [ -r "$STATE_FILE" ]; then
                v=""
                read -r v < "$STATE_FILE" 2>/dev/null || true
                case "$v" in 0|off) want=0 ;; esac
            fi

            cur=""
            read -r cur < "$LED/brightness" 2>/dev/null || cur=""
            if [ "$cur" != "$want" ]; then
                printf '%s' "$want" > "$LED/brightness" 2>/dev/null || true
            fi
        fi

        sleep "$POLL"
    done
}

case "${1:-toggle}" in
    on)     apply 1 ;;
    off)    apply 0 ;;
    toggle) if [ "$(current_state)" = "on" ]; then apply 0; else apply 1; fi ;;
    status) current_state ;;
    keep)   keep ;;
    *)      echo "Uso: $0 [on|off|toggle|status|keep]" >&2; exit 2 ;;
esac
