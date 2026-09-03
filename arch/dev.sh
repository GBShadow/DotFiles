#!/usr/bin/env bash
# ==============================================================================
# Ambiente de Desenvolvimento — GBShadow (Arch Linux)
# Rodar DEPOIS do arch/install.sh (base) e arch/apps.sh (aplicativos).
#
# - Docker + Docker Compose (serviço + grupo do usuário)
# - nvm + Node.js LTS (o ~/.zshrc dos dotfiles já carrega o nvm)
# - C#/.NET: SDK via pacman + setup-csharp.sh dos dotfiles (tools globais +
#   Mason/OmniSharp no Neovim) — o script oficial usa apt só se o SDK faltar,
#   então com o SDK do pacman instalado ele funciona igual no Arch.
#
# Uso: ./dev.sh
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
    # Mantém o sudo ativo em segundo plano durante downloads e instalações
    while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
    log_ok "Ambiente Arch Linux confirmado."
}

# ------------------------------------------------------------------------------
# 1. Docker + Compose
# ------------------------------------------------------------------------------
install_docker() {
    log_header "Instalando Docker + Docker Compose"
    sudo pacman -S --needed --noconfirm docker docker-compose
    sudo systemctl enable --now docker.service
    if ! groups "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER"
        log_warn "Usuário adicionado ao grupo 'docker' — faça logout/login para usar docker sem sudo."
    else
        log_ok "Usuário já está no grupo 'docker'."
    fi
    sudo docker --version && (docker compose version 2>/dev/null || sudo docker compose version || true)
    log_ok "Docker ativo (systemctl)."
}

# ------------------------------------------------------------------------------
# 2. nvm + Node.js LTS (~/.zshrc dos dotfiles já carrega o nvm automaticamente)
# ------------------------------------------------------------------------------
install_nvm_node() {
    log_header "Instalando nvm + Node.js LTS"
    if [ ! -f "$HOME/.nvm/nvm.sh" ]; then
        git clone --depth=1 https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
        log_ok "nvm clonado em ~/.nvm."
    else
        log_ok "nvm já instalado em ~/.nvm."
    fi

    # Carrega o nvm na sessão atual e instala o LTS
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm alias default 'lts/*'
    log_ok "Node $(node --version) (LTS) definido como padrão."
}

# ------------------------------------------------------------------------------
# 3. C# / .NET (SDK via pacman; tools globais + Mason via script dos dotfiles)
# ------------------------------------------------------------------------------
install_dotnet_csharp() {
    log_header "Instalando ambiente C# / .NET"

    if dotnet --list-sdks 2>/dev/null | grep -q -E "[0-9]+\.[0-9]+"; then
        log_ok ".NET SDK já instalado:"
        dotnet --list-sdks
    else
        # Pacote versionado do extra do Arch — mesmo runtime do apt dotnet-sdk-8.0
        sudo pacman -S --needed --noconfirm dotnet-sdk-8.0
        log_ok ".NET SDK 8.0 instalado via pacman."
    fi

    # Reaproveita o script dos dotfiles: variáveis de ambiente (~/.zshrc),
    # ferramentas globais (csharpier, dotnet-ef) e Mason (omnisharp, netcoredbg).
    if [ -f "$DOTFILES_DIR/scripts/setup-csharp.sh" ]; then
        bash "$DOTFILES_DIR/scripts/setup-csharp.sh"
    else
        log_warn "scripts/setup-csharp.sh não encontrado; instale as tools manualmente."
    fi
}

# ------------------------------------------------------------------------------
# Execução principal
# ------------------------------------------------------------------------------
preflight
install_docker
install_nvm_node
install_dotnet_csharp

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN}✔ Ambiente de desenvolvimento pronto:${NC}"
echo -e "  Docker + Compose (grupo 'docker' aplicado — relelogue a sessão)"
echo -e "  nvm + Node $(node --version 2>/dev/null || echo 'LTS') (ZSH já carrega sozinho)"
echo -e "  .NET SDK + csharpier + dotnet-ef + OmniSharp/netcoredbg (Mason/Neovim)"
echo -e "${GREEN}==============================================================================${NC}"
