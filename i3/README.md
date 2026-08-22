# 🪟 Configuração do i3 Window Manager — Catppuccin Mocha

Ambiente de trabalho completo baseado no gerenciador de janelas **i3**, estilizado com a paleta **Catppuccin Mocha**, gaps entre janelas, compositor **Picom** com blur (*dual_kawase*) e terminal **Alacritty** com transparência de 50%.

---

## 📂 Estrutura dos Arquivos

```
i3/
├── README.md               # Documentação e atalhos
├── setup.sh                # Script de instalação de dependências e configuração
├── config                  # Configuração principal do i3 (~/.config/i3/config)
├── monitors.sh             # Script de detecção e seleção de monitor externo
├── alacritty.toml          # Configuração do Alacritty (~/.config/alacritty/alacritty.toml)
├── picom.conf              # Configuração do Picom (~/.config/picom/picom.conf)
├── i3status-rust.toml      # Barra de status colorida (~/.config/i3status-rust/config.toml)
├── Xresources              # Cores X11 Dark Catppuccin (~/.Xresources)
├── rofi/
│   ├── config.rasi         # Configuração principal do Rofi
│   └── slate.rasi          # Tema Slate Catppuccin para Rofi
└── scripts/
    └── kof2002.sh          # Launcher do KOF 2002 com gamemoderun (silencioso)
```

---

## 🎨 Recursos e Estilização

3. **Status Bar (i3status-rust) & Alternador de Áudio:**
   - Blocos informativos coloridos por categoria (CPU, RAM, Disco, Rede/WiFi, Saída de Áudio, Volume e Relógio) no estilo Catppuccin Mocha.
   - Botão interativo **`󰍹 HDMI` / `󰓃 Fone`** e bloco de volume na barra superior: clique com botão esquerdo para alternar a saída de áudio instantaneamente, botão direito para abrir o `pavucontrol`.
2. **Transparência & Blur (Picom + Alacritty):**
   - Compositor **Picom** acelerado por hardware (GLX / Intel HD Graphics) com filtro de blur *dual_kawase* e cantos arredondados (8px).
   - Terminal **Alacritty** com opacidade em `0.50` (50% de transparência).

3. **Status Bar (i3status-rust):**
   - Blocos informativos coloridos por categoria (CPU, RAM, Disco, Rede/WiFi, Volume e Relógio) no estilo Catppuccin Mocha.

4. **Launcher & Menus (Rofi):**
   - Tema *Slate* personalizado com fonte JetBrainsMono Nerd Font e pesquisa rápida de aplicações.

---

## 🚀 Instalação Rápida

Para instalar todas as dependências e restaurar as configurações:

```bash
cd ~/dotfiles/i3
chmod +x setup.sh
./setup.sh
```

O script detecta sua distribuição (Debian/Ubuntu via `apt`, Arch via `pacman`, Fedora via `dnf`), instala pacotes necessários, fontes JetBrainsMono Nerd Font, configura os diretórios em `~/.config` e recarrega a sessão.

---

## ⌨️ Tabela de Atalhos Principais

O atalho principal (**$mod**) está definido como a tecla <kbd>Super</kbd> (Windows).

| Atalho | Ação |
| :--- | :--- |
| <kbd>$mod</kbd> + <kbd>q</kbd> | **Fechar janela focada** |
| <kbd>$mod</kbd> + <kbd>Enter</kbd> | Abrir terminal (**Alacritty**) |
| <kbd>$mod</kbd> + <kbd>d</kbd> | Abrir menu de aplicativos (**Rofi**) |
| <kbd>$mod</kbd> + <kbd>0</kbd> | Menu de energia (**Power Menu**) |
| <kbd>$mod</kbd> + <kbd>k</kbd> | Iniciar KOF 2002 UM (*gamemode / silencioso*) |
| <kbd>$mod</kbd> + <kbd>a</kbd> | **Alternar saída de áudio** (*HDMI ↔ Fones/Alto-falantes*) |
| <kbd>$mod</kbd> + <kbd>f</kbd> | Alternar tela cheia (*Fullscreen*) |
| <kbd>$mod</kbd> + <kbd>Shift</kbd> + <kbd>Espaço</kbd> | Alternar janela flutuante |
| <kbd>$mod</kbd> + <kbd>h</kbd> | Dividir janelas na horizontal |
| <kbd>$mod</kbd> + <kbd>v</kbd> | Dividir janelas na vertical |
| <kbd>$mod</kbd> + <kbd>1</kbd> ... <kbd>5</kbd> | Alternar para workspace 1 a 5 |
| <kbd>$mod</kbd> + <kbd>Shift</kbd> + <kbd>1</kbd> ... <kbd>5</kbd> | Mover janela focada para workspace 1 a 5 |
| <kbd>$mod</kbd> + <kbd>←</kbd> <kbd>↓</kbd> <kbd>↑</kbd> <kbd>→</kbd> | Mudar foco entre janelas |
| <kbd>$mod</kbd> + <kbd>Shift</kbd> + <kbd>←</kbd> <kbd>↓</kbd> <kbd>↑</kbd> <kbd>→</kbd> | Mover janela na direção indicada |
| <kbd>$mod</kbd> + <kbd>r</kbd> | Modo redimensionar janelas (<kbd>Esc</kbd> para sair) |
| <kbd>$mod</kbd> + <kbd>Shift</kbd> + <kbd>r</kbd> | Recarregar configuração do i3 |
| <kbd>$mod</kbd> + <kbd>Shift</kbd> + <kbd>e</kbd> | Encerrar sessão do i3 |
| <kbd>Print</kbd> | Captura de tela inteira |
| <kbd>$mod</kbd> + <kbd>Print</kbd> | Captura de seleção de área |
| <kbd>Fn</kbd> + Volume / Brilho | Controle multimídia e brilho da tela |
