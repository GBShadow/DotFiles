# 🪟 Configuração do i3 Window Manager — Catppuccin Mocha

Ambiente de trabalho completo baseado no gerenciador de janelas **i3**, estilizado com a paleta **Catppuccin Mocha**, gaps entre janelas, barra de status **Polybar**, compositor **Picom** com blur (*dual_kawase*), cursor branco **Breeze_Light** e terminal **Alacritty** com transparência de 50%.

---

## 📂 Estrutura dos Arquivos

```
i3/
├── README.md               # Documentação e atalhos
├── setup.sh                # Script de instalação de dependências e configuração
├── config                  # Configuração principal do i3 (~/.config/i3/config)
├── monitors.sh             # Script de detecção de monitor externo e ajuste de wallpaper
├── alacritty.toml          # Configuração do Alacritty (~/.config/alacritty/alacritty.toml)
├── picom.conf              # Configuração do Picom (~/.config/picom/picom.conf)
├── Xresources              # Cores X11 Dark Catppuccin + Cursor (~/.Xresources)
├── polybar/
│   ├── config.ini          # Configuração do Polybar com tema Catppuccin Mocha
│   └── launch.sh           # Script de inicialização do Polybar e apps de bandeja
├── gsimplecal/
│   └── config              # Configuração do calendário popup (~/.config/gsimplecal/config)
├── xsettingsd/
│   └── xsettingsd.conf     # Configuração de temas GTK e cursor Breeze_Light
├── gtk-3.0/
│   └── settings.ini        # Configurações GTK 3
├── rofi/
│   ├── config.rasi         # Configuração principal do Rofi
│   └── slate.rasi          # Tema Slate Catppuccin para Rofi
└── scripts/
    ├── audio-toggle.sh     # Script para alternar saída de áudio (HDMI ↔ Fones)
    ├── powermenu.sh        # Menu Rofi para Desligar / Reiniciar / Suspender / Logout
    └── kof2002.sh          # Launcher do KOF 2002 com gamemoderun (silencioso)
```

---

## 🎨 Recursos e Estilização

1. **Status Bar (Polybar) & Bandeja de Ícones:**
   * Tema **Catppuccin Mocha** multi-colorido em formato de pílulas.
   * **Bandeja de ícones (Tray)** posicionada **no início** da seção direita, seguida pelos blocos de sistema (CPU, RAM, Disco, Rede, Áudio, Volume, Data/Hora, Power).
   * **Calendário Interativo:** Clique com botão esquerdo sobre o bloco de data/relógio para abrir o calendário popup (`gsimplecal`). Clique fora ou clique novamente para fechar.
   * **Alternador de Áudio:** Clique com botão esquerdo no bloco de áudio (`󰍹 HDMI` / `󰓃 Fone`) ou use <kbd>$mod</kbd> + <kbd>a</kbd> para alternar a saída de som. Botão direito no volume abre o `pavucontrol`.

2. **Cursor Breeze Branco (`Breeze_Light`):**
   * Tema de cursor `Breeze_Light` configurado globalmente em X11 (`.Xresources`), GTK 2/3/4 e `xsettingsd`.

3. **Papel de Parede Automático:**
   * Script `monitors.sh` detecta a resolução ativa do monitor externo ($1440 \times 900$) e aplica `feh --bg-fill` para preencher toda a tela sem cortes ou barras pretas.

4. **Transparência & Blur (Picom + Alacritty):**
   * Compositor **Picom** com aceleração por hardware (GLX), blur *dual_kawase* e cantos arredondados.
   * Terminal **Alacritty** com opacidade em `0.50` (50% de transparência).

5. **Launcher & Menus (Rofi):**
   * Tema *Slate* personalizado com fonte JetBrainsMono Nerd Font e menu de energia integrado (<kbd>$mod</kbd> + <kbd>0</kbd>).

---

## 🚀 Instalação Rápida

Para instalar todas as dependências e restaurar as configurações:

```bash
cd ~/dotfiles/i3
chmod +x setup.sh
./setup.sh
```

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
