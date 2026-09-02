#!/usr/bin/env bash
# ==============================================================================
# game-run.sh — liga o modo jogo, abre o emulador e desliga ao fechar
#
# Uso:
#   game-run.sh melonds
#   game-run.sh flatpak run org.duckstation.DuckStation
#
# Equivale a: game-mode.sh on -> emulador -> game-mode.sh off
# (instalado em ~/.local/bin pelo i3/setup.sh)
# ==============================================================================
set -e

if [ $# -eq 0 ]; then
    echo "uso: game-run.sh <emulador> [argumentos]"
    echo "ex.: game-run.sh melonds"
    echo "     game-run.sh flatpak run org.duckstation.DuckStation"
    exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"

"$DIR/game-mode.sh" on
echo "── iniciando: $* ──"
"$@" || true
"$DIR/game-mode.sh" off
