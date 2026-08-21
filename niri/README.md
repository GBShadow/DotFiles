# 🌌 Niri + Noctalia Dotfiles

Configurações completas para o compositor Wayland **Niri** e a shell **Noctalia**, com suporte a controle de brilho via software (para monitores externos em adaptadores VGA/HDMI) e roteamento avançado de áudio no **WirePlumber / PipeWire** (HDMI + Alto-falantes simultâneos).

---

## 📦 1. Pacotes Necessários (Fedora)

Após formatar o sistema, habilite os repositórios COPR e instale os pacotes:

```bash
# 1. Habilitar COPR do Niri e do Noctalia
sudo dnf copr enable yalter/niri -y
sudo dnf copr enable noctalia-shell/noctalia -y

# 2. Instalar Niri, Noctalia e utilitários essenciais
sudo dnf install -y \
  niri \
  noctalia \
  alacritty \
  swaylock \
  playerctl \
  wireplumber \
  pipewire-utils \
  libnotify

# 3. Instalar Rust / Cargo (para o daemon de brilho wl-gammarelay-rs)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cargo install wl-gammarelay-rs
```

---

## 🚀 2. Restauração Automática

Para aplicar todas as configurações automaticamente em um único comando:

```bash
cd ~/dotfiles/niri
chmod +x setup.sh
./setup.sh
```

---

## 🛠 3. Restauração Manual (Passo a Passo)

Caso prefira copiar manualmente os arquivos:

1. **Configuração do Niri e Scripts**:
   ```bash
   mkdir -p ~/.config/niri/scripts
   cp config.kdl ~/.config/niri/
   cp scripts/*.sh ~/.config/niri/scripts/
   chmod +x ~/.config/niri/scripts/*.sh
   ```

2. **Configuração do WirePlumber (Áudio HDMI + Analógico simultâneos)**:
   ```bash
   mkdir -p ~/.config/wireplumber/wireplumber.conf.d
   cp wireplumber/50-alsa-rename.conf ~/.config/wireplumber/wireplumber.conf.d/
   systemctl --user restart wireplumber
   ```

3. **Configuração do Noctalia**:
   ```bash
   mkdir -p ~/.config/noctalia
   cp noctalia/settings.toml ~/.config/noctalia/
   ```

---

## ⌨️ 4. Principais Atalhos de Teclado

### 🔆 Brilho do Monitor Externo (Software / Gama com OSD)
| Atalho | Ação |
| :--- | :--- |
| `Super + F5` ou `Super + Alt + ↓` | Diminuir brilho (-5%) |
| `Super + F6` ou `Super + Alt + ↑` | Aumentar brilho (+5%) |
| `XF86MonBrightnessDown / Up` | Teclas multimídia padrão de brilho |

> **Nota Técnica**: Como o monitor externo está conectado por adaptador VGA para HDMI, o controle de brilho físico por DDC/CI não responde. O script utiliza o daemon `wl-gammarelay-rs` (protocolo Wayland `wlr-gamma-control`) para escurecer a imagem via software sem flickering e exibe o OSD visual do Noctalia.

---

### 🔊 Controle e Alternância de Áudio
| Atalho | Ação |
| :--- | :--- |
| `Super + Alt + A` | **Alternar saída de som**: Monitor Externo (HDMI) $\leftrightarrow$ Alto-falantes / Fones |
| `XF86AudioRaiseVolume` | Aumentar volume |
| `XF86AudioLowerVolume` | Diminuir volume |
| `XF86AudioMute` | Mutar / Desmutar volume |
| `XF86AudioPlay / Prev / Next` | Controles de mídia (Playerctl) |

---

### 🌙 Noctalia Shell
| Atalho | Ação |
| :--- | :--- |
| `Super + Espaço` | Abrir / Fechar Launcher de Aplicativos |
| `Super + S` | Abrir / Fechar Centro de Controle |
| `Super + ,` | Abrir Configurações do Noctalia |

---

### 🪟 Niri (Janelas, Colunas e Espaços de Trabalho)
| Atalho | Ação |
| :--- | :--- |
| `Super + T` | Abrir Terminal (`alacritty`) |
| `Super + Q` | Fechar janela em foco |
| `Super + O` | Alternar Modo Visão Geral (*Overview*) |
| `Super + F` | Maximizar coluna |
| `Super + Shift + F` | Janela em tela cheia (*fullscreen*) |
| `Super + V` | Alternar janela flutuante (*floating*) |
| `Super + H/J/K/L` ou `Setas` | Navegação entre colunas e janelas |
| `Super + 1` até `Super + 9` | Alternar para a área de trabalho 1 a 9 |
| `Super + Shift + E` | Sair da sessão do Niri |
| `Super + Alt + L` | Bloquear a tela (`swaylock`) |
| `Print` | Captura de tela interativa |
