#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação e Restauração das Configurações do Niri + Noctalia
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Iniciando configuração do Niri + Noctalia..."

# 1. Cria diretórios de destino
echo "==> Criando diretórios em ~/.config..."
mkdir -p ~/.config/niri/scripts
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
mkdir -p ~/.config/noctalia
mkdir -p ~/.local/bin

# 2. Copia/linka as configurações do Niri
echo "==> Copiando configurações do Niri e Scripts..."
cp "$DOTFILES_DIR/config.kdl" ~/.config/niri/config.kdl
cp "$DOTFILES_DIR/scripts/brightness.sh" ~/.config/niri/scripts/brightness.sh
cp "$DOTFILES_DIR/scripts/audio-toggle.sh" ~/.config/niri/scripts/audio-toggle.sh
chmod +x ~/.config/niri/scripts/*.sh

# 3. Copia as configurações do WirePlumber (Áudio HDMI + Analógico simultâneos)
echo "==> Configurando WirePlumber (saídas de áudio)..."
cp "$DOTFILES_DIR/wireplumber/50-alsa-rename.conf" ~/.config/wireplumber/wireplumber.conf.d/50-alsa-rename.conf

# 4. Copia as configurações do Noctalia
echo "==> Configurando Noctalia..."
cp "$DOTFILES_DIR/noctalia/settings.toml" ~/.config/noctalia/settings.toml

# 5. Verifica e instala o wl-gammarelay-rs (controle de brilho via software)
if ! command -v wl-gammarelay-rs >/dev/null 2>&1 && [ ! -f "$HOME/.cargo/bin/wl-gammarelay-rs" ]; then
    echo "==> Instalando wl-gammarelay-rs via Cargo (necessário para controle de brilho via software)..."
    if command -v cargo >/dev/null 2>&1; then
        cargo install wl-gammarelay-rs
        ln -sf ~/.cargo/bin/wl-gammarelay-rs ~/.local/bin/wl-gammarelay-rs || true
    else
        echo "[AVISO] Rust/Cargo não encontrado. Instale o Rust com: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        echo "        Depois execute: cargo install wl-gammarelay-rs"
    fi
else
    if [ -f "$HOME/.cargo/bin/wl-gammarelay-rs" ]; then
        ln -sf ~/.cargo/bin/wl-gammarelay-rs ~/.local/bin/wl-gammarelay-rs || true
    fi
    echo "==> wl-gammarelay-rs já está instalado."
fi

# 6. Reinicia o WirePlumber para aplicar as regras de áudio se estiver rodando
if systemctl --user is-active --quiet wireplumber; then
    echo "==> Recarregando WirePlumber..."
    systemctl --user restart wireplumber || true
fi

# 7. Recarrega a configuração do Niri se estiver em execução
if command -v niri >/dev/null 2>&1; then
    niri msg action load-config-file >/dev/null 2>&1 || true
fi

echo ""
echo "=============================================================================="
echo "✔ Configurações do Niri e Noctalia restauradas com sucesso!"
echo "=============================================================================="
