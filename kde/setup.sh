#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação — Retroiluminação de teclado USB no KDE Plasma (Wayland)
# ------------------------------------------------------------------------------
# Os dotfiles originais controlavam a luz do teclado apenas com `xset`, que só
# funciona no X11 (i3). No Wayland (KWin/Plasma) é preciso escrever direto no
# sysfs, o que exige uma regra udev para liberar a permissão.
#
# Este módulo:
#   1. instala o script portátil em ~/.local/bin/kbd-backlight.sh
#   2. instala a regra udev (permissão de escrita no LED) em /etc/udev/rules.d
#   3. instala o autostart que liga a luz no login
#   4. registra um atalho global do Plasma (padrão: Meta+K)
#   5. liga a luz imediatamente
#
# Uso: ./setup.sh
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KDE_DIR="$DOTFILES_DIR/kde"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Atalho global (formato do Plasma). Pode ser sobrescrito no ambiente:
#   KBD_BACKLIGHT_SHORTCUT="Meta+ScrollLock" ./setup.sh
SHORTCUT="${KBD_BACKLIGHT_SHORTCUT:-Meta+K}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ [INFO]${NC} $1"; }
log_ok()      { echo -e "${GREEN}✔ [OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}⚠ [AVISO]${NC} $1"; }
log_header() {
    echo ""
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "  ${CYAN}🚀 $1${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo ""
}

log_header "Retroiluminação do teclado USB — KDE Plasma (Wayland)"

# ------------------------------------------------------------------------------
# 0. Confere se a sessão é Plasma
# ------------------------------------------------------------------------------
if [ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ]; then
    log_ok "Sessão KDE Plasma detectada (${XDG_SESSION_TYPE:-?})."
else
    log_warn "Sessão não parece ser KDE Plasma (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-vazio})."
    log_warn "O script instalado também funciona em X11 (i3) e Niri; seguindo mesmo assim."
fi

# Ferramentas do KDE para editar o kglobalshortcutsrc
KWRITE="$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)"
KREAD="$(command -v kreadconfig6 || command -v kreadconfig5 || true)"

# ------------------------------------------------------------------------------
# 1. Script portátil em ~/.local/bin
# ------------------------------------------------------------------------------
mkdir -p "$HOME/.local/bin"
cp "$SCRIPTS_DIR/kbd-backlight.sh" "$HOME/.local/bin/kbd-backlight.sh"
chmod 755 "$HOME/.local/bin/kbd-backlight.sh"
log_ok "Script instalado em ~/.local/bin/kbd-backlight.sh"

# ------------------------------------------------------------------------------
# 2. Regra udev (permissão de escrita no LED do teclado)
# ------------------------------------------------------------------------------
UDEV_SRC="$SCRIPTS_DIR/udev/90-kbd-backlight.rules"
UDEV_DST="/etc/udev/rules.d/90-kbd-backlight.rules"

if [ -f "$UDEV_SRC" ]; then
    if [ -f "$UDEV_DST" ] && cmp -s "$UDEV_SRC" "$UDEV_DST"; then
        log_ok "Regra udev já instalada ($UDEV_DST)."
    else
        log_info "Instalando regra udev em $UDEV_DST (requer sudo)..."
        if sudo cp "$UDEV_SRC" "$UDEV_DST" && sudo chmod 644 "$UDEV_DST"; then
            sudo udevadm control --reload-rules || true
            sudo udevadm trigger --subsystem-match=leds || true
            log_ok "Regra udev instalada e recarregada."
        else
            log_warn "Sem sudo disponível. Instale manualmente mais tarde:"
            log_warn "  sudo cp $UDEV_SRC $UDEV_DST"
            log_warn "  sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=leds"
        fi
    fi
else
    log_warn "Regra udev não encontrada em $UDEV_SRC."
fi

# ------------------------------------------------------------------------------
# 3. Autostart (liga a luz no login)
# ------------------------------------------------------------------------------
mkdir -p "$HOME/.config/autostart"
cp "$KDE_DIR/autostart/kbd-backlight.desktop" "$HOME/.config/autostart/kbd-backlight.desktop"
chmod 644 "$HOME/.config/autostart/kbd-backlight.desktop"
log_ok "Autostart instalado em ~/.config/autostart/kbd-backlight.desktop"

# ------------------------------------------------------------------------------
# 4. Atalho global do Plasma (comando → toggle da luz)
# ------------------------------------------------------------------------------
# O KGlobalAccelD (hospedado pelo kwin_wayland no Plasma 6) procura comandos
# globais em ~/.local/share/kglobalaccel/<nome>.desktop e lê o atalho do grupo
# [services][<nome>.desktop] em ~/.config/kglobalshortcutsrc.
mkdir -p "$HOME/.local/share/kglobalaccel"
install -m 755 "$KDE_DIR/kglobalaccel/kbd-backlight.desktop" \
    "$HOME/.local/share/kglobalaccel/kbd-backlight.desktop"
log_ok "Comando global instalado em ~/.local/share/kglobalaccel/kbd-backlight.desktop"

if [ -n "$KWRITE" ]; then
    current="$($KREAD --file kglobalshortcutsrc --group services --group kbd-backlight.desktop --key _launch 2>/dev/null || true)"
    if [ -z "$current" ]; then
        "$KWRITE" --file kglobalshortcutsrc --group services --group kbd-backlight.desktop --key _launch "$SHORTCUT"
        log_ok "Atalho global registrado: $SHORTCUT (alternar retroiluminação)"
    else
        log_info "Atalho global já definido ($current) — preservado."
    fi
    # Força sincronização em disco para o daemon ler no próximo login
    "$KWRITE" --file kglobalshortcutsrc --group services --group kbd-backlight.desktop --key _k_friendly_name "Retroiluminação do Teclado" 2>/dev/null || true
else
    log_warn "kwriteconfig6 não encontrado — defina o atalho manualmente em:"
    log_warn "  Configurações do Sistema → Atalhos → Adicionar comando → $HOME/.local/bin/kbd-backlight.sh toggle"
fi

# ------------------------------------------------------------------------------
# 5. Liga a luz agora
# ------------------------------------------------------------------------------
if "$HOME/.local/bin/kbd-backlight.sh" on; then
    led="$("$HOME/.local/bin/kbd-backlight.sh" status 2>/dev/null || true)"
    log_ok "Retroiluminação ligada (estado: ${led:-?})."
else
    log_warn "Não foi possível ligar a luz agora — verifique a regra udev/grupo do usuário."
fi

# ------------------------------------------------------------------------------
# Resumo
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}==============================================================================${NC}"
log_ok "Módulo KDE instalado!"
echo ""
echo "  • Luz ligada automaticamente no login (autostart)."
echo "  • Atalho global: $SHORTCUT  (alternar)"
echo "  • Alternar também pela própria tecla Scroll Lock."
echo ""
log_warn "O atalho global só entra em vigor após sair e entrar de novo na sessão"
echo "         (o KGlobalAccelD lê os comandos na inicialização do kwin_wayland)."
echo -e "${CYAN}==============================================================================${NC}"
