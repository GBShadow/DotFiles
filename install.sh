#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Master Setup & Installer — GBShadow
# Executa a configuração completa ou modular do ecossistema:
# ZSH, MPV, Neovim (LazyVim), i3 Window Manager, Niri Compositor, GitUI, Configurações Locais do $HOME e omp.
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem cor

log_info() {
    echo -e "${BLUE}ℹ [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✔ [OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠ [AVISO]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "  ${CYAN}🚀 $1${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo ""
}

# 1. Configuração do ZSH
setup_zsh() {
    log_header "Configurando ZSH (Oh My Zsh + Zinit + Starship + Plugins)"
    if [ -f "$DOTFILES_DIR/zsh/setup.sh" ]; then
        bash "$DOTFILES_DIR/zsh/setup.sh"
        log_success "Módulo ZSH configurado com sucesso!"
    else
        log_warn "Script $DOTFILES_DIR/zsh/setup.sh não encontrado."
    fi
}

# 2. Configuração do MPV
setup_mpv() {
    log_header "Configurando MPV Media Player (Aceleração VA-API + Auto-Resume)"
    if [ -f "$DOTFILES_DIR/mpv/setup.sh" ]; then
        bash "$DOTFILES_DIR/mpv/setup.sh"
        log_success "Módulo MPV configurado com sucesso!"
    else
        log_warn "Script $DOTFILES_DIR/mpv/setup.sh não encontrado."
    fi
}

# 3. Configuração do Neovim (LazyVim)
setup_nvim() {
    log_header "Configurando Neovim (LazyVim + Performance + Catppuccin)"
    mkdir -p "$HOME/.config"
    if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        log_info "Fazendo backup da pasta ~/.config/nvim existente..."
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%s)"
    fi

    ln -sfn "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    log_success "Link simbólico criado: ~/.config/nvim -> $DOTFILES_DIR/nvim"
}

# 4. Configuração do i3 Window Manager
setup_i3() {
    log_header "Configurando i3 Window Manager (Polybar + Picom + Breeze_Light + Rofi)"
    if [ -f "$DOTFILES_DIR/i3/setup.sh" ]; then
        bash "$DOTFILES_DIR/i3/setup.sh"
        log_success "Módulo i3 configurado com sucesso!"
    else
        log_warn "Script $DOTFILES_DIR/i3/setup.sh não encontrado."
    fi
}

# 5. Configuração do Niri Compositor
setup_niri() {
    log_header "Configurando Niri Compositor + Noctalia + WirePlumber"
    if [ -f "$DOTFILES_DIR/niri/setup.sh" ]; then
        bash "$DOTFILES_DIR/niri/setup.sh"
        log_success "Módulo Niri configurado com sucesso!"
    else
        log_warn "Script $DOTFILES_DIR/niri/setup.sh não encontrado."
    fi
}

# 6. Configuração do GitUI
setup_gitui() {
    log_header "Configurando tema Catppuccin Mocha para o GitUI"
    mkdir -p "$HOME/.config/gitui"
    if [ -f "$DOTFILES_DIR/gitui/theme.ron" ]; then
        cp "$DOTFILES_DIR/gitui/theme.ron" "$HOME/.config/gitui/theme.ron"
        log_success "Tema do GitUI aplicado em ~/.config/gitui/theme.ron"
    fi
}

# 7. Configurações Locais do $HOME (git, shell, tema GTK, papel de parede, omp)
setup_home() {
    log_header "Aplicando configurações locais (\$HOME: git, tema, wallpaper, omp)"
    if [ -f "$DOTFILES_DIR/home/setup.sh" ]; then
        bash "$DOTFILES_DIR/home/setup.sh"
        log_success "Módulo Home (configs locais + omp) configurado com sucesso!"
    else
        log_warn "Script $DOTFILES_DIR/home/setup.sh não encontrado."
    fi
}

# 8. Execução Completa (Tudo)
setup_all() {
    log_header "Iniciando Instalação e Configuração Completa de Todos os Módulos"
    setup_zsh
    setup_mpv
    setup_nvim
    setup_gitui
    setup_i3
    setup_home
    
    # Pergunta opcional para niri se estiver interativo, ou configura direto
    if [ "$NON_INTERACTIVE" = "true" ]; then
        setup_niri
    else
        echo ""
        read -p "Deseja configurar também o compositor Niri (Wayland)? [s/N]: " resp_niri
        if [[ "$resp_niri" =~ ^([sS][iI][mM]|[sS])$ ]]; then
            setup_niri
        fi
    fi

    log_header "🎉 Parabéns! Toda a configuração dos dotfiles foi concluída!"
    echo -e "${GREEN}Resumo dos módulos configurados:${NC}"
    echo -e "  ✔ Shell: ZSH + Oh My Zsh + Zinit + Starship Prompt + Aliases"
    echo -e "  ✔ Vídeo/Mídia: MPV com VA-API e retomada automática (auto-resume)"
    echo -e "  ✔ Editor: Neovim (LazyVim Otimizado)"
    echo -e "  ✔ Git TUI: GitUI (Catppuccin Mocha)"
    echo -e "  ✔ Desktop X11: i3-gaps + Polybar + Picom Blur + Rofi + Xsettingsd"
    echo -e "  ✔ Local: gitconfig/profile/bashrc, Tema Catppuccin, Wallpaper e omp"
    echo ""
}

# Exibição do Menu
show_menu() {
    clear || true
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "  📁 ${GREEN}Dotfiles Installer & Configurator — GBShadow${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo ""
    echo -e " Escolha os módulos que deseja instalar/configurar:"
    echo ""
    echo -e "  ${GREEN}1)${NC} 🚀 Instalar TUDO (Completo: ZSH + MPV + Neovim + i3 + GitUI)"
    echo -e "  ${GREEN}2)${NC} 💻 Apenas ZSH (Oh My Zsh + Zinit + Starship + YouTube/MPV Helpers)"
    echo -e "  ${GREEN}3)${NC} 🎬 Apenas MPV (Aceleração por Hardware VA-API + Auto-Resume)"
    echo -e "  ${GREEN}4)${NC} 📝 Apenas Neovim (LazyVim + Configurações de Performance)"
    echo -e "  ${GREEN}5)${NC} 🪟 Apenas i3 Window Manager (Polybar, Picom, Rofi, Áudio, Temas)"
    echo -e "  ${GREEN}6)${NC} 🌊 Apenas Niri Compositor (Wayland + Noctalia + WirePlumber)"
    echo -e "  ${GREEN}7)${NC} 🐙 Apenas GitUI (Tema Catppuccin)"
    echo -e "  ${GREEN}8)${NC} 🏠 Apenas Configurações Locais do \$HOME (git, tema, wallpaper, omp)"
    echo -e "  ${RED}0)${NC} ❌ Sair"
    echo ""
    echo -e "${CYAN}==============================================================================${NC}"
    read -p "Digite a opção desejada [0-8]: " opcao

    case "$opcao" in
        1) setup_all ;;
        2) setup_zsh ;;
        3) setup_mpv ;;
        4) setup_nvim ;;
        5) setup_i3 ;;
        6) setup_niri ;;
        7) setup_gitui ;;
        8) setup_home ;;
        0) echo "Operação cancelada."; exit 0 ;;
        *) log_warn "Opção inválida!"; exit 1 ;;
    esac
}

# Tratamento de argumentos por linha de comando (ex: ./install.sh --all, --zsh, etc.)
if [ "$#" -gt 0 ]; then
    case "$1" in
        --all|-a)
            NON_INTERACTIVE=true
            setup_all
            ;;
        --zsh|-z)
            setup_zsh
            ;;
        --mpv|-m)
            setup_mpv
            ;;
        --nvim|-n)
            setup_nvim
            ;;
        --i3|-i)
            setup_i3
            ;;
        --niri)
            setup_niri
            ;;
        --gitui|-g)
            setup_gitui
            ;;
        --home|-l)
            setup_home
            ;;
        --help|-h)
            echo "Uso: $0 [OPÇÃO]"
            echo "Opções disponíveis:"
            echo "  --all, -a    Executa toda a configuração de forma automática"
            echo "  --zsh, -z    Configura apenas o ZSH e complementos"
            echo "  --mpv, -m    Configura apenas o MPV e yt-dlp"
            echo "  --nvim, -n   Configura apenas o Neovim"
            echo "  --i3, -i     Configura apenas o i3 Window Manager e Polybar"
            echo "  --niri       Configura apenas o compositor Niri (Wayland)"
            echo "  --gitui, -g  Aplica apenas o tema do GitUI"
            echo "  --home, -l    Aplica as configurações locais do \$HOME (git, tema, wallpaper, omp)"
            echo "  --help, -h   Exibe esta ajuda"
            ;;
        *)
            log_warn "Opção desconhecida: $1. Use --help para ver as opções."
            exit 1
            ;;
    esac
else
    # Sem argumentos, exibe o menu interativo
    show_menu
fi
