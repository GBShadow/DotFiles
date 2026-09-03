#!/usr/bin/env bash
# ==============================================================================
# Instalador de Aplicativos — GBShadow (Arch Linux)
# Rodar DEPOIS do arch/install.sh (base do sistema).
#
# Nativos (extra/multilib): Obsidian, Bitwarden, Krita, Steam, Alacritty,
#   GNOME Calculator, feh (imagens), Zathura (PDF), File Roller,
#   breeze-cursors, dotnet-runtime, NTFS/exFAT/FAT, zip/7zip
# AUR:   Thorium Browser, ZapZap, MarkText, LinuxToys, OnlyOffice,
#   OpenTabletDriver, MelonDS
# GitHub Releases: DuckStation (AppImage oficial)
#
# Uso: ./apps.sh
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    # Mantém o sudo ativo em segundo plano durante compilações longas
    while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
    log_ok "Ambiente Arch Linux confirmado."
}

# ------------------------------------------------------------------------------
# 1. Habilita repositório [multilib] (necessário para o Steam)
# ------------------------------------------------------------------------------
enable_multilib() {
    log_header "Configurando repositórios e mirrors"
    # Corrige caso includes de repositórios testing tenham sido descomentados sem o cabeçalho
    sudo sed -i '/^#\[.*-testing\]/{n;s/^Include/#Include/}' /etc/pacman.conf 2>/dev/null || true

    # Prioriza mirrors do Brasil para evitar timeouts/throttling de CDNs internacionais (ex: Fastly)
    if ! head -n 15 /etc/pacman.d/mirrorlist | grep -q 'ufscar\|unicamp'; then
        sudo sed -i '/## Worldwide/i ## Brazil (priorizados)\nServer = https://mirror.ufscar.br/archlinux/$repo/os/$arch\nServer = https://mirrors.ic.unicamp.br/archlinux/$repo/os/$arch\nServer = https://archlinux.c3sl.ufpr.br/$repo/os/$arch\n' /etc/pacman.d/mirrorlist 2>/dev/null || true
        log_ok "Mirrors rápidos do Brasil priorizados no /etc/pacman.d/mirrorlist."
    fi

    if grep -q '^\[multilib\]' /etc/pacman.conf; then
        log_ok "[multilib] já está habilitado."
    else
        # Descomenta apenas o cabeçalho e o Include da seção multilib
        sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
        log_ok "[multilib] habilitado no /etc/pacman.conf."
    fi
    sudo pacman -Syu --noconfirm
}

# ------------------------------------------------------------------------------
# 2. AUR helper (yay-bin, binário pré-compilado — ideal para 2 núcleos)
# ------------------------------------------------------------------------------
install_aur_helper() {
    log_header "Instalando AUR helper (yay-bin)"
    if command -v yay >/dev/null 2>&1; then
        log_ok "yay já instalado."
        return 0
    fi
    local tmp
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    ( cd "$tmp/yay-bin" && makepkg -si --noconfirm )
    rm -rf "$tmp"
    log_ok "yay instalado."
}

# ------------------------------------------------------------------------------
# 3. Aplicativos nativos + utilitários de montagem/compactação
# ------------------------------------------------------------------------------
install_native_apps() {
    log_header "Instalando aplicativos nativos (pacman)"

    sudo pacman -S --needed --noconfirm \
        obsidian \
        bitwarden gnome-keyring \
        krita \
        steam \
        alacritty \
        gnome-calculator \
        gamemode \
        thunar thunar-archive-plugin thunar-volman tumbler gvfs gvfs-goa \
        gnome-online-accounts gnome-control-center \
        feh \
        zathura zathura-pdf-poppler \
        file-roller \
        dotnet-runtime \
        breeze-cursors \
        ntfs-3g exfatprogs dosfstools udisks2 \
        zip unzip 7zip cabextract

    log_ok "Pacotes nativos instalados."
}

# ------------------------------------------------------------------------------
# 4. Aplicativos do AUR (um por vez: falha isolada não aborta o resto)
# ------------------------------------------------------------------------------
install_aur_apps() {
    log_header "Instalando aplicativos do AUR (yay)"

    local pkgs=(thorium-browser-bin zapzap marktext-bin onlyoffice-bin linuxtoys-bin opentabletdriver melonds-bin)
    local p
    for p in "${pkgs[@]}"; do
        if yay -S --needed --noconfirm "$p"; then
            log_ok "$p instalado."
        else
            log_warn "Falha ao instalar $p (veja o erro acima). Continuando..."
        fi
    done

    # Fallback: se o linuxtoys-bin falhar, usa o instalador oficial
    if ! pacman -Q linuxtoys-bin >/dev/null 2>&1 && ! command -v linuxtoys >/dev/null 2>&1; then
        log_warn "linuxtoys-bin falhou. Tentando instalador oficial (linux.toys)..."
        curl -fsSL https://linux.toys/install.sh | bash || log_warn "Instalador oficial do LinuxToys também falhou; instale manualmente depois."
    fi
}

# ------------------------------------------------------------------------------
# 5. DuckStation via Flatpak (método oficial do emulador)
# ------------------------------------------------------------------------------
install_duckstation() {
    log_header "Instalando DuckStation (GitHub Releases)"

    local install_dir="/opt/duckstation"
    local bin_path="/usr/local/bin/duckstation"
    local desktop_file="/usr/share/applications/duckstation.desktop"
    local icon_path="/usr/share/icons/hicolor/512x512/apps/duckstation.png"
    local url="https://github.com/stenzek/duckstation/releases/download/latest/DuckStation-x64.AppImage"

    sudo mkdir -p "$install_dir"
    log_info "Baixando DuckStation-x64.AppImage do GitHub..."
    sudo curl -fsSL -o "$install_dir/DuckStation.AppImage" "$url"
    sudo chmod +x "$install_dir/DuckStation.AppImage"

    sudo ln -sf "$install_dir/DuckStation.AppImage" "$bin_path"

    # Extrai o ícone oficial
    local tmp
    tmp="$(mktemp -d)"
    (
        cd "$tmp"
        "$install_dir/DuckStation.AppImage" --appimage-extract usr/share/icons/hicolor/512x512/apps/org.duckstation.DuckStation.png >/dev/null 2>&1 || true
        if [ -f squashfs-root/usr/share/icons/hicolor/512x512/apps/org.duckstation.DuckStation.png ]; then
            sudo mkdir -p /usr/share/icons/hicolor/512x512/apps
            sudo cp squashfs-root/usr/share/icons/hicolor/512x512/apps/org.duckstation.DuckStation.png "$icon_path"
        fi
    )
    rm -rf "$tmp"

    # Cria entrada no menu de aplicativos (.desktop)
    sudo tee "$desktop_file" >/dev/null << 'EOF'
[Desktop Entry]
Name=DuckStation
Comment=PlayStation 1 Emulator
Exec=/usr/local/bin/duckstation %f
Icon=duckstation
Terminal=false
Type=Application
Categories=Game;Emulator;
Keywords=playstation;ps1;psx;emulator;
StartupWMClass=DuckStation
EOF

    log_ok "DuckStation instalado com sucesso em $install_dir."
}

# ------------------------------------------------------------------------------
# 6. Pós-configuração de serviços
# ------------------------------------------------------------------------------
post_config() {
    log_header "Ativando serviços"
    systemctl --user enable --now opentabletdriver.service 2>/dev/null \
        && log_ok "OpenTabletDriver: serviço de usuário ativado." \
        || log_warn "Serviço do OpenTabletDriver não ativado automaticamente; quando estiver na sessão gráfica, rode: systemctl --user enable --now opentabletdriver"
    echo ""
    log_info "Notas:"
    echo "  - Bitwarden usa o chaveiro do sistema (gnome-keyring instalado). Se o"
    echo "    aplicativo pedir senha de chaveiro, defina uma no primeiro uso."
    echo "  - LinuxToys abre pelo menu do i3/rofi ou comando: linuxtoys"
}
# ------------------------------------------------------------------------------
# Execução principal
# ------------------------------------------------------------------------------
preflight
enable_multilib
install_aur_helper
install_native_apps
install_aur_apps
install_duckstation
post_config

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN}✔ Aplicativos instalados:${NC}"
echo -e "  Nativos : Obsidian, Bitwarden, Krita, Steam, Alacritty,"
echo -e "            GNOME Calculator, feh, Zathura (PDF), File Roller, Thunar, Google Drive (GOA)"
echo -e "  Utilit. : NTFS/exFAT/FAT (mount), udisks2, zip/unzip/7zip/cabextract"
echo -e "  AUR     : Thorium, ZapZap, MarkText, LinuxToys, OnlyOffice, OpenTabletDriver, MelonDS"
echo -e "  GitHub  : DuckStation (AppImage em /opt/duckstation)"
echo -e "${GREEN}==============================================================================${NC}"
