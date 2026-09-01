#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação e Configuração do MPV + YT-DLP
# (Hardware Acceleration Intel VA-API + Auto-Resume + YouTube CLI Helpers)
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================================================="
echo "  🎬 Configurando MPV Media Player (Aceleração por Hardware + Auto-Resume)"
echo "=============================================================================="
echo ""

# 1. Instalação do MPV, drivers VA-API e pipx/yt-dlp
install_dependencies() {
    echo "==> [1/3] Verificando e instalando pacotes (mpv, va-driver, pipx, yt-dlp)..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y mpv va-driver-all i965-va-driver intel-media-va-driver vainfo pipx curl ffmpeg
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Syu --needed --noconfirm mpv libva-intel-driver intel-media-driver libva-utils python-pipx curl ffmpeg
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y mpv libva-intel-driver intel-media-driver libva-utils python3-pipx curl ffmpeg
    fi

    # Garante yt-dlp atualizado via pipx se não estiver no sistema
    if ! command -v yt-dlp >/dev/null 2>&1; then
        echo "--> Instalando yt-dlp atualizado via pipx..."
        pipx install yt-dlp || true
    fi
}

# 2. Criação do diretório de configuração do MPV
setup_directories() {
    echo "==> [2/3] Criando diretório de configuração ~/.config/mpv..."
    mkdir -p "$HOME/.config/mpv"
    mkdir -p "$HOME/.config/mpv/scripts"
    mkdir -p "$HOME/.config/mpv/watch_later"
}

# 3. Cópia do arquivo mpv.conf
copy_configs() {
    echo "==> [3/3] Aplicando mpv.conf..."
    if [ -f "$HOME/.config/mpv/mpv.conf" ]; then
        cp "$HOME/.config/mpv/mpv.conf" "$HOME/.config/mpv/mpv.conf.bak.$(date +%s)" 2>/dev/null || true
    fi

    cp "$DOTFILES_DIR/mpv.conf" "$HOME/.config/mpv/mpv.conf"
}

install_dependencies
setup_directories
copy_configs

echo ""
echo "=============================================================================="
echo "✔ MPV configurado com sucesso!"
echo "Recursos ativos:"
echo " - Aceleração gráfica por hardware (VA-API / OpenGL)"
echo " - Retomada automática do ponto onde o vídeo parou (save-position-on-quit=yes)"
echo " - Formatos otimizados para YouTube (H.264 até 720p fluído)"
echo "=============================================================================="
