#!/usr/bin/env bash
# ==============================================================================
# Script de Menu de Energia (Power Menu) para i3 / Rofi
# Opções: Desligar, Reiniciar, Encerrar Sessão, Suspender, Bloquear
# ==============================================================================

shutdown="  Desligar"
reboot="  Reiniciar"
logout="󰗽  Encerrar Sessão"
suspend="  Suspender"
lock="  Bloquear"

options="$shutdown\n$reboot\n$logout\n$suspend\n$lock"

if [ -f "$HOME/.config/rofi/slate.rasi" ]; then
    theme_opt=(-theme "$HOME/.config/rofi/slate.rasi")
else
    theme_opt=()
fi

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power" "${theme_opt[@]}")

case "$chosen" in
    "$shutdown")
        systemctl poweroff
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$logout")
        i3-msg exit
        ;;
    "$suspend")
        systemctl suspend
        ;;
    "$lock")
        i3lock -c 11111b
        ;;
esac
