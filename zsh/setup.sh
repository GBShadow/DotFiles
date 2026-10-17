#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação e Configuração Completa do ZSH
# (Oh My Zsh + Zinit + Plugins + Spaceship Prompt + Aliases + MPV Helpers)
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================================================="
echo "  🚀 Instalando e configurando ZSH (Oh My Zsh + Zinit + Spaceship)"
echo "=============================================================================="
echo ""

# 1. Instalação dos pacotes do sistema
install_packages() {
    echo "==> [1/5] Instalando dependências (zsh, git, curl, fzf)..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y zsh git curl fzf
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Syu --needed --noconfirm zsh git curl fzf
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y zsh git curl fzf
    else
        echo "[AVISO] Gerenciador de pacotes não suportado automaticamente. Verifique se o zsh, git e curl estão instalados."
    fi
}

# 2. Instalação do Oh My Zsh (se não existir)
install_oh_my_zsh() {
    echo "==> [2/5] Verificando Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "--> Baixando e instalando Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "--> Oh My Zsh já instalado."
    fi
}

# 3. Instalação do Zinit (Plugin Manager rápido)
install_zinit() {
    echo "==> [3/5] Verificando Zinit..."
    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
    if [ ! -d "$ZINIT_HOME" ]; then
        echo "--> Clonando repositório Zinit..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    else
        echo "--> Zinit já instalado."
    fi
}

# 4. Instalação do Spaceship Prompt como tema do Oh My Zsh
install_spaceship() {
    echo "==> [4/5] Verificando Spaceship Prompt..."
    local themes_dir="$HOME/.oh-my-zsh/custom/themes"
    local spaceship_dir="$themes_dir/spaceship-prompt"
    local theme_link="$themes_dir/spaceship.zsh-theme"

    mkdir -p "$themes_dir"
    if [ ! -d "$spaceship_dir" ]; then
        echo "--> Baixando Spaceship Prompt..."
        git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$spaceship_dir"
    else
        echo "--> Spaceship Prompt já instalado."
    fi
    if [ ! -e "$theme_link" ] && [ ! -L "$theme_link" ]; then
        ln -s "$spaceship_dir/spaceship.zsh-theme" "$theme_link"
    fi
}

# 5. Cópia dos arquivos de configuração
copy_configs() {
    echo "==> [5/5] Aplicando arquivos de configuração (~/.zshrc, ~/.bash_aliases)..."
    
    # Backup se já existir arquivo
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)" 2>/dev/null || true
    fi

    cp "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    
    if [ -f "$DOTFILES_DIR/.bash_aliases" ]; then
        cp "$DOTFILES_DIR/.bash_aliases" "$HOME/.bash_aliases"
    fi

    # Define ZSH como shell padrão do usuário se não for
    if [ "$SHELL" != "$(which zsh)" ] && command -v zsh >/dev/null 2>&1; then
        echo "--> Definindo ZSH como shell padrão..."
        sudo chsh -s "$(which zsh)" "$USER" 2>/dev/null || chsh -s "$(which zsh)" 2>/dev/null || true
    fi
}

install_packages
install_oh_my_zsh
install_zinit
install_spaceship
copy_configs

echo ""
echo "=============================================================================="
echo "✔ Configuração do ZSH instalada com sucesso!"
echo "Para iniciar, digite: zsh"
echo "=============================================================================="
