#!/usr/bin/env bash
# ==============================================================================
# game-run.sh — liga o modo jogo, abre o emulador e desliga ao fechar
#
# Uso:
#   game-run.sh duckstation [argumentos]
#   game-run.sh melonDS [argumentos]
#
# Equivale a: game-mode.sh on -> emulador -> game-mode.sh off
# ==============================================================================
set -e

if [ $# -eq 0 ]; then
    echo "uso: game-run.sh <emulador> [argumentos]"
    echo "ex.: game-run.sh duckstation"
    echo "     game-run.sh melonDS"
    exit 1
fi

BIN_NAME="$1"
shift

# Tratamento para capitalização do melonDS
if [ "$BIN_NAME" = "melonds" ] && ! command -v melonds >/dev/null 2>&1 && command -v melonDS >/dev/null 2>&1; then
    BIN_NAME="melonDS"
fi

# Localiza game-mode.sh
GAME_MODE="$(which game-mode.sh 2>/dev/null || echo "$HOME/.local/bin/game-mode.sh")"

cleanup() {
    "$GAME_MODE" off
}
trap cleanup EXIT INT TERM

"$GAME_MODE" on
echo "── iniciando: $BIN_NAME $* ──"
"$BIN_NAME" "$@" || true
