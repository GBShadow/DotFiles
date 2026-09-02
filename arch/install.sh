#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Base Setup — GBShadow
# Prepara um Arch Linux puro + i3 para o notebook Celeron 1037U (SSD 120GB)
# e aplica os módulos deste repositório (ZSH, MPV, Neovim, GitUI, i3).
#
# Rodar APÓS o primeiro boot do sistema recém-instalado, como usuário normal
# (com permissão sudo). O particionamento e a instalação base estão descritos
# em INSTALACAO-ARCH.md.
#
# Uso: ./install.sh [--wifi]
#   --wifi   instala também o driver AIC8800 (DKMS) sem perguntar
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ [INFO]${NC} $1"; }
log_ok()      { echo -e "${GREEN}✔ [OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}⚠ [AVISO]${NC} $1"; }
log_error()   { echo -e "${RED}✖ [ERRO]${NC} $1" >&2; }
log_header()  {
    echo ""
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "  ${CYAN}$1${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo ""
}

WIFI_AUTO=false
[ "${1:-}" = "--wifi" ] && WIFI_AUTO=true

# ------------------------------------------------------------------------------
# 0. Verificações iniciais
# ------------------------------------------------------------------------------
preflight() {
    if ! command -v pacman >/dev/null 2>&1; then
        log_error "Este script é exclusivo para Arch Linux (pacman não encontrado)."
        exit 1
    fi
    if [ "$EUID" -eq 0 ]; then
        log_error "NÃO rode como root. Rode como seu usuário normal (o script usa sudo)."
        exit 1
    fi
    sudo -v
    log_ok "Ambiente Arch Linux confirmado."
}

# ------------------------------------------------------------------------------
# 1. Base do sistema: X11, áudio, rede, fontes e toolchain DKMS
# ------------------------------------------------------------------------------
install_base() {
    log_header "Instalando base do sistema (X11, áudio, rede, fontes, DKMS)"
    sudo pacman -Syu --needed --noconfirm \
        xorg-server xorg-xinit mesa \
        pulseaudio pulseaudio-alsa alsa-utils pavucontrol \
        networkmanager nm-connection-editor network-manager-applet \
        ttf-jetbrainsmono-nerd ttf-dejavu noto-fonts \
        base-devel git curl unzip dkms linux-headers github-cli \
        neovim xdg-user-dirs

    sudo systemctl enable --now NetworkManager
    # TRIM semanal para o SSD (NÃO usar discard contínuo: write amplification)
    log_ok "Base instalada e NetworkManager ativo."
}

# ------------------------------------------------------------------------------
# 2. Otimizações para o Celeron 1037U (replica a fluidez do MiniOS)
#    - ZRAM (zstd, metade da RAM) no lugar de swap em disco
#    - earlyoom (evita congelamento quando a RAM enche)
#    - fstrim semanal (SSD 120GB, sem discard contínuo)
# ------------------------------------------------------------------------------
apply_optimizations() {
    log_header "Aplicando otimizações (ZRAM, earlyoom, fstrim)"

    # ZRAM: swap compactado em RAM — o truque de performance do MiniOS
    sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

    # Ajustes de memória para ZRAM-only
    sudo tee /etc/sysctl.d/99-zram.conf >/dev/null <<'EOF'
# ZRAM: prioriza swap em RAM comprimida
vm.swappiness = 100
vm.page-cluster = 0
EOF

    # earlyoom: mata o app que comeu a RAM antes de congelar o desktop inteiro
    sudo pacman -S --needed --noconfirm earlyoom zram-generator
    sudo systemctl enable --now earlyoom

    # TRIM semanal para o SSD (não usar discard contínuo: wrote amplification)
    sudo systemctl enable --now fstrim.timer

    log_ok "ZRAM (zstd, ram/2), earlyoom e fstrim.timer ativados."
}

# ------------------------------------------------------------------------------
# 3. Driver Wi-Fi AIC8800 (adaptador Mercusys) — opcional
# ------------------------------------------------------------------------------
install_wifi() {
    log_header "Driver Wi-Fi AIC8800 (DKMS)"

    local resp=""
    if [ "$WIFI_AUTO" = "true" ]; then
        resp="s"
    else
        read -p "Instalar o driver AIC8800/Mercusys agora? [s/N]: " resp
    fi

    if [[ "$resp" =~ ^([sS][iI][mM]|[sS])$ ]]; then
        if [ -f "$DOTFILES_DIR/scripts/install-wifi-aic8800.sh" ]; then
            sudo bash "$DOTFILES_DIR/scripts/install-wifi-aic8800.sh"
            log_ok "Driver AIC8800 instalado (DKMS). Reinicie para carregar o módulo."
        else
            log_warn "Script scripts/install-wifi-aic8800.sh não encontrado."
        fi
    else
        log_info "Pulando driver Wi-Fi (instale depois com: sudo bash scripts/install-wifi-aic8800.sh)."
    fi
}

# ------------------------------------------------------------------------------
# 4. Módulos dos dotfiles (mesma ordem do install.sh master; Niri fica de fora
#    porque o alvo é i3/X11 — rode ./install.sh --niri se quiser depois)
# ------------------------------------------------------------------------------
apply_dotfiles() {
    log_header "Aplicando módulos dos dotfiles (ZSH, MPV, Neovim, GitUI, i3)"
    bash "$DOTFILES_DIR/install.sh" --zsh
    bash "$DOTFILES_DIR/install.sh" --mpv
    bash "$DOTFILES_DIR/install.sh" --nvim
    bash "$DOTFILES_DIR/install.sh" --gitui
    bash "$DOTFILES_DIR/install.sh" --i3
    log_ok "Dotfiles aplicados. No próximo login o ZSH será o shell padrão."
}

# ------------------------------------------------------------------------------
# 5. omp (Oh My Pi) — instala o binário oficial em ~/.local/bin
# ------------------------------------------------------------------------------
install_omp() {
    log_header "Instalando omp (Oh My Pi)"
    if command -v omp >/dev/null 2>&1; then
        log_ok "omp já instalado: $(omp --version 2>/dev/null | head -1)."
        return 0
    fi
    curl -fsSL https://omp.sh/install | sh
    export PATH="$HOME/.local/bin:$PATH"
    if command -v omp >/dev/null 2>&1; then
        log_ok "omp instalado: $(omp --version | head -1)."
    else
        log_warn "omp não encontrado no PATH — reabra o terminal e rode 'omp --version'."
    fi
}

# ------------------------------------------------------------------------------
# 6. Configurações locais do $HOME (dotfiles/home): git, tema, wallpaper, omp
# ------------------------------------------------------------------------------
apply_local_configs() {
    log_header "Aplicando configurações locais do \$HOME"
    bash "$DOTFILES_DIR/home/setup.sh"
}
# ------------------------------------------------------------------------------
# Execução principal
# ------------------------------------------------------------------------------
preflight
install_base
apply_optimizations
install_wifi
apply_dotfiles
apply_local_configs
install_omp

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN}✔ Base do Arch configurada! Próximo passo:${NC}"
echo -e "  ${GREEN}1)${NC} cd ~/dotfiles/arch && ./apps.sh   (instala todos os aplicativos)"
echo -e "  ${GREEN}2)${NC} cd ~/dotfiles/arch && ./dev.sh     (Docker + Node LTS + C#/.NET)"
echo -e "  ${GREEN}3)${NC} Reinicie e faça login no i3"
echo -e "${GREEN}==============================================================================${NC}"
