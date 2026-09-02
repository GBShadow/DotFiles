#!/usr/bin/env bash
# ==============================================================================
# Configurações Locais do $HOME — GBShadow
# Aplica os arquivos pessoais versionados em dotfiles/home/:
#   .gitconfig, .profile, .bashrc, .gtkrc-2.0, .xinitrc (i3), .xsessionrc,
#   .fehbg (papel de parede), tema GTK Catppuccin Mocha e configs do omp
#   (marketplaces + manifests de plugins).
#
# Cada arquivo existente que divergir é preservado com backup .bak.<timestamp>.
# Uso: ./setup.sh
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_SRC="$DOTFILES_DIR/home"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log_ok()     { echo -e "${GREEN}✔ [OK]${NC} $1"; }
log_header() {
    echo ""
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "  ${CYAN}$1${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo ""
}

# Copia $2 -> $1 com backup se já existir e divergir
install_home_file() {
    local dest="$1" src="$2" mode="${3:-}"
    if [ -f "$dest" ] && ! cmp -s "$dest" "$src"; then
        mv "$dest" "$dest.bak.$(date +%s)"
    fi
    cp "$src" "$dest"
    [ -n "$mode" ] && chmod "$mode" "$dest"
    log_ok "$(basename "$dest") aplicado."
}

# ------------------------------------------------------------------------------
# Execução principal
# ------------------------------------------------------------------------------
log_header "Configurações locais do \$HOME (dotfiles/home)"

install_home_file "$HOME/.gitconfig"   "$HOME_SRC/gitconfig"
install_home_file "$HOME/.profile"     "$HOME_SRC/profile"
install_home_file "$HOME/.bashrc"      "$HOME_SRC/bashrc"
install_home_file "$HOME/.gtkrc-2.0"   "$HOME_SRC/gtkrc-2.0"
install_home_file "$HOME/.xsessionrc"  "$HOME_SRC/xsessionrc"
install_home_file "$HOME/.xinitrc"     "$HOME_SRC/xinitrc"
install_home_file "$HOME/.fehbg"       "$HOME_SRC/fehbg" 755

# Tema GTK Catppuccin Mocha (referenciado por GTK_THEME no .profile/.xsessionrc)
mkdir -p "$HOME/.themes"
rm -rf "$HOME/.themes/catppuccin-mocha-blue-standard+default"
cp -r "$HOME_SRC/themes/catppuccin-mocha-blue-standard+default" "$HOME/.themes/"
log_ok "Tema Catppuccin Mocha instalado em ~/.themes/."

# Papel de parede
mkdir -p "$HOME/Pictures"
cp "$HOME_SRC/wallpapers/1375178.png" "$HOME/Pictures/"
log_ok "Papel de parede instalado em ~/Pictures/1375178.png."

# Configurações locais do omp (Oh My Pi): marketplaces + manifests de plugins.
# natives/skills/cache/stats são baixados/gerados pelo próprio omp.
mkdir -p "$HOME/.omp/plugins"
install_home_file "$HOME/.omp/marketplaces.json" "$HOME_SRC/omp/marketplaces.json"
for f in "$HOME_SRC/omp/plugins-manifests/"*; do
    install_home_file "$HOME/.omp/plugins/$(basename "$f")" "$f"
done
log_ok "Configurações do omp aplicadas (reabra o omp para sincronizar plugins)."

echo ""
log_ok "Configurações locais aplicadas."
