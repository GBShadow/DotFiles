#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação e Restauração das Configurações do i3 Window Manager
# Tema: Catppuccin Mocha + Gaps + Alacritty Transparente + Picom Blur + Polybar
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================================================="
echo "  🚀 Iniciando configuração do i3 Window Manager (Catppuccin Mocha)"
echo "=============================================================================="
echo ""

# 1. Detecta o gerenciador de pacotes e instala dependências do sistema
install_dependencies() {
    echo "==> [1/6] Verificando e instalando dependências do sistema..."

    if command -v apt-get >/dev/null 2>&1; then
        echo "--> Detectado Debian/Ubuntu/Mint (apt)"
        sudo apt-get update -y
        sudo apt-get install -y \
            i3 \
            i3lock \
            polybar \
            gsimplecal \
            breeze-cursor-theme \
            alacritty \
            picom \
            rofi \
            feh \
            brightnessctl \
            pulseaudio-utils \
            playerctl \
            xfce4-screenshooter \
            network-manager-gnome \
            copyq \
            xsettingsd \
            x11-xserver-utils \
            x11-xkb-utils \
            xdotool \
            dbus-x11 \
            curl \
            unzip \
            fontconfig \
            libconfig-dev
    elif command -v pacman >/dev/null 2>&1; then
        echo "--> Detectado Arch Linux (pacman)"
        sudo pacman -Syu --needed --noconfirm \
            i3-wm \
            i3lock \
            polybar \
            gsimplecal \
            breeze-gtk \
            alacritty \
            picom \
            rofi \
            feh \
            brightnessctl \
            pulseaudio \
            playerctl \
            xfce4-screenshooter \
            network-manager-applet \
            copyq \
            xsettingsd \
            xorg-xrandr \
            xorg-xrdb \
            xorg-xset \
            xorg-setxkbmap \
            xdotool \
            curl \
            unzip
    elif command -v dnf >/dev/null 2>&1; then
        echo "--> Detectado Fedora / Red Hat (dnf)"
        sudo dnf install -y \
            i3 \
            i3lock \
            polybar \
            gsimplecal \
            breeze-cursor-theme \
            alacritty \
            picom \
            rofi \
            feh \
            brightnessctl \
            pulseaudio-utils \
            playerctl \
            xfce4-screenshooter \
            network-manager-applet \
            copyq \
            xsettingsd \
            xrandr \
            xrdb \
            setxkbmap \
            xdotool \
            curl \
            unzip
    else
        echo "[AVISO] Gerenciador de pacotes não reconhecido automaticamente."
        echo "        Certifique-se de ter instalado: i3, polybar, gsimplecal, alacritty, picom, rofi, feh, brightnessctl, playerctl, copyq, etc."
    fi
}

# 2. Instala JetBrainsMono Nerd Font se não estiver presente
install_fonts() {
    echo "==> [2/6] Verificando fontes (JetBrainsMono Nerd Font)..."
    if ! fc-list | grep -qi "JetBrainsMono"; then
        echo "--> Baixando JetBrainsMono Nerd Font..."
        FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNF"
        mkdir -p "$FONT_DIR"
        TMP_ZIP="/tmp/JetBrainsMono.zip"
        curl -fLo "$TMP_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
        unzip -o "$TMP_ZIP" -d "$FONT_DIR" >/dev/null
        rm -f "$TMP_ZIP"
        fc-cache -f "$FONT_DIR"
        echo "--> Fontes instaladas com sucesso!"
    else
        echo "--> JetBrainsMono Nerd Font já instalada."
    fi
}

# 3. Cria diretórios de destino
setup_directories() {
    echo "==> [3/6] Criando diretórios em ~/.config, ~/.icons e ~/.local/bin..."
    mkdir -p "$HOME/.config/i3"
    mkdir -p "$HOME/.config/polybar"
    mkdir -p "$HOME/.config/gsimplecal"
    mkdir -p "$HOME/.config/alacritty"
    mkdir -p "$HOME/.config/picom"
    mkdir -p "$HOME/.config/rofi"
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/xsettingsd"
    mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
    mkdir -p "$HOME/.icons/default"
    mkdir -p "$HOME/.local/share/icons/default"
    mkdir -p "$HOME/.local/bin"
}

# 4. Copia as configurações do i3 e componentes
copy_configs() {
    echo "==> [4/6] Aplicando arquivos de configuração..."

    # i3 config & monitor helper
    cp "$DOTFILES_DIR/config" "$HOME/.config/i3/config"
    cp "$DOTFILES_DIR/monitors.sh" "$HOME/.config/i3/monitors.sh"
    chmod +x "$HOME/.config/i3/monitors.sh"

    # Polybar (Barra de status Catppuccin Mocha com Tray no início e Calendário no clique)
    if [ -d "$DOTFILES_DIR/polybar" ]; then
        cp "$DOTFILES_DIR/polybar/config.ini" "$HOME/.config/polybar/config.ini"
        cp "$DOTFILES_DIR/polybar/launch.sh" "$HOME/.config/polybar/launch.sh"
        chmod +x "$HOME/.config/polybar/launch.sh"
    fi

    # gsimplecal (Calendário pop-up)
    if [ -d "$DOTFILES_DIR/gsimplecal" ]; then
        cp "$DOTFILES_DIR/gsimplecal/config" "$HOME/.config/gsimplecal/config"
    fi

    # Alacritty (Terminal com transparência)
    cp "$DOTFILES_DIR/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

    # Picom (Compositor com blur dual_kawase e transparência)
    cp "$DOTFILES_DIR/picom.conf" "$HOME/.config/picom/picom.conf"

    # Rofi (Launcher & Power Menu slate theme)
    cp "$DOTFILES_DIR/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
    cp "$DOTFILES_DIR/rofi/slate.rasi" "$HOME/.config/rofi/slate.rasi"

    # Xresources (X11 Dark Catppuccin Colors + Breeze_Light Cursor)
    cp "$DOTFILES_DIR/Xresources" "$HOME/.Xresources"
    if command -v xrdb >/dev/null 2>&1; then
        xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
    fi

    # Configuração de cursor Breeze_Light
    cat << 'EOF' > "$HOME/.icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Breeze_Light
EOF
    cp "$HOME/.icons/default/index.theme" "$HOME/.local/share/icons/default/index.theme"

    # xsettingsd e GTK settings
    if [ -f "$DOTFILES_DIR/xsettingsd/xsettingsd.conf" ]; then
        cp "$DOTFILES_DIR/xsettingsd/xsettingsd.conf" "$HOME/.config/xsettingsd/xsettingsd.conf"
    fi
    if [ -f "$DOTFILES_DIR/gtk-3.0/settings.ini" ]; then
        cp "$DOTFILES_DIR/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
    fi

    # Notificações no topo (xfce4-notifyd)
    if [ -f "$DOTFILES_DIR/xfce4/xfce4-notifyd.xml" ]; then
        cp "$DOTFILES_DIR/xfce4/xfce4-notifyd.xml" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-notifyd.xml"
        if command -v xfconf-query >/dev/null 2>&1; then
            xfconf-query -c xfce4-notifyd -p /notify-location -s "top-right" 2>/dev/null || true
        fi
    fi

    # Scripts auxiliares do i3 (~/.local/bin)
    if [ -d "$DOTFILES_DIR/scripts" ]; then
        for script in "$DOTFILES_DIR/scripts"/*.sh; do
            if [ -f "$script" ]; then
                script_name="$(basename "$script")"
                cp "$script" "$HOME/.local/bin/$script_name"
                chmod +x "$HOME/.local/bin/$script_name"
            fi
        done
    fi
}

# 5. Aplica cursor e recarrega serviços
reload_services() {
    echo "==> [5/5] Atualizando sessão ativa..."

    # Aplica cursor no X11 root window
    if command -v xsetroot >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        xsetroot -cursor_name left_ptr 2>/dev/null || true
    fi

    # Reinicia picom
    if pgrep -x picom >/dev/null 2>&1; then
        killall picom 2>/dev/null || true
    fi
    if [ -n "$DISPLAY" ]; then
        picom -b --config "$HOME/.config/picom/picom.conf" 2>/dev/null || true
    fi

    # Inicia/Reinicia Polybar
    if [ -f "$HOME/.config/polybar/launch.sh" ] && [ -n "$DISPLAY" ]; then
        "$HOME/.config/polybar/launch.sh" 2>/dev/null || true
    fi

    # Recarrega o i3 se estiver rodando
    if command -v i3-msg >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        i3-msg restart 2>/dev/null || i3-msg reload 2>/dev/null || true
        echo "--> i3 recarregado com sucesso!"
    fi
}

# Execução principal
install_dependencies
install_fonts
setup_directories
copy_configs
reload_services

echo ""
echo "=============================================================================="
echo "✔ Configurações do i3 (Catppuccin Mocha + Polybar + Breeze_Light + Picom) instaladas com sucesso!"
echo "=============================================================================="
