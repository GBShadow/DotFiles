#!/bin/bash
# Launch KOF 2002 via Steam Flatpak in silent mode with gamemode
# AppID: 222440
# This avoids loading the full Steam interface, saving memory
# Uses CachyOS Proton (cachyos-11.0-20260703-slr)

STEAM_FLATPAK="com.valvesoftware.Steam"
GAME_APPID="222440"
GAME_NAME="The King of Fighters 2002 Unlimited Match"
STEAM_DATA="$HOME/.var/app/$STEAM_FLATPAK/.local/share/Steam"
GAME_DIR="$STEAM_DATA/steamapps/common/$GAME_NAME"

# Verify game directory exists
if [ ! -d "$GAME_DIR" ]; then
    echo "ERROR: Game directory not found: $GAME_DIR"
    exit 1
fi

# Environment variables for optimal performance
export PROTON_USE_WINED3D=0
export PROTON_USE_D9VK=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache"
export __GL_THREADED_OPTIMIZATIONS=1
export mesa_glthread=true
export MESA_GLSL_CACHE_DISABLE=0
export DXVK_HUD=0
export DXVK_LOG_LEVEL=none

# Launch Steam in silent mode (no main UI) with gamemoderun
# The -silent flag prevents Steam UI from appearing
# Games are launched with the configured Proton (CachyOS) via Steam
gamemoderun flatpak run "$STEAM_FLATPAK" \
    -silent \
    -nominimal \
    -applaunch "$GAME_APPID" \
    2>/dev/null
