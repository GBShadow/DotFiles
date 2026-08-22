# 📁 Dotfiles — GBShadow

Repositório pessoal de **dotfiles**, configurado para alta produtividade, inicialização instantânea e máxima fluidez no **Neovim (LazyVim)**, com ajustes refinados para desempenho em hardware modesto (CPUs dual-core / gráficos integrados).

---

## 📂 Estrutura do Repositório

```
dotfiles/
├── README.md
├── i3/                    # Configuração completa do i3 + Alacritty + Picom + i3status-rust
│   ├── README.md          # Guia de instalação e atalhos do i3
│   ├── setup.sh           # Script de instalação de dependências e configuração
│   ├── config             # Configuração principal do i3 (Gaps + Mod+q + Catppuccin)
│   ├── alacritty.toml     # Terminal com transparência e cores Mocha
│   ├── picom.conf         # Compositor GLX com blur dual_kawase e transparência
│   ├── i3status-rust.toml # Barra de status com temas individuais por bloco
│   └── rofi/              # Launcher de apps e power menu (slate theme)
├── niri/                  # Configuração do compositor Niri + Noctalia + Scripts
│   ├── README.md          # Guia de instalação e lista de atalhos
│   ├── setup.sh           # Script de restauração automática pós-formatação
│   ├── config.kdl         # Configuração principal do Niri
│   ├── scripts/           # Scripts de brilho (software) e alternância de áudio
│   ├── wireplumber/       # Regras de saída de som simultânea (HDMI + Analógico)
│   └── noctalia/          # Configuração da shell Noctalia
└── nvim/                  # Configuração completa do Neovim (LazyVim)
    ├── init.lua
    ├── lazy-lock.json
    ├── lazyvim.json
    ├── stylua.toml
    ├── .gitignore
    ├── .neoconf.json
    └── lua/
        ├── config/
        │   ├── autocmds.lua   # Comandos automáticos (ex: cursorline dinâmico)
        │   ├── keymaps.lua    # Atalhos personalizados
        │   ├── lazy.lua       # Bootstrap e configurações do gerenciador Lazy.nvim
        │   └── options.lua    # Opções do Neovim (renderização, timeout, buffers)
        └── plugins/
            ├── colorscheme.lua # Tema Catppuccin Mocha e integrações de UI
            ├── explorer.lua    # Configuração do gerenciador de arquivos (Snacks/Neo-tree)
            └── performance.lua # Otimizações de CPU/GPU (LSP, Treesitter, UI, Git)
```

---

## 🚀 Instalação e Uso

### Pré-requisitos
- **Neovim** >= 0.10.0
- **Git**
- **Ripgrep** (`rg`) e **fd** (`fd-find`)
- **Compilador C** (`gcc` ou `clang`) para os parsers do Treesitter
- **Node.js** e **npm** (para LSPs de TypeScript, Tailwind, etc.)

### Passo a passo

1. **Clone o repositório na sua pasta pessoal (`~/dotfiles`):**
   ```bash
   git clone https://github.com/GBShadow/dotfiles.git ~/dotfiles
   ```

2. **Crie o link simbólico para a pasta de configuração do Neovim:**
   ```bash
   # Faça backup de alguma configuração prévia caso exista
   mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true

   # Crie o symlink
   ln -s ~/dotfiles/nvim ~/.config/nvim
   ```

3. **Inicie o Neovim:**
   ```bash
   nvim
   ```
   O `lazy.nvim` fará o download e a compilação de todos os plugins automaticamente na primeira inicialização.

---

## 🛠️ O que foi configurado e otimizado

### 1. 🗂️ Gerenciador de Arquivos (`lua/plugins/explorer.lua`)
Ajustado o explorador padrão (**Snacks Explorer**) e adicionada compatibilidade com **Neo-tree**:
- **Arquivos Ocultos (Dotfiles):** Exibe arquivos e pastas que começam com ponto (ex: `.gitignore`, `.env`, `.config`, `.neoconf.json`).
- **Arquivos Ignorados pelo Git:** Arquivos listados no `.gitignore` continuam visíveis na árvore de arquivos (ex: pastas `dist/`, `build/`, arquivos de log).
- **Filtro Customizado:** Mantém a pasta `node_modules/` **permanentemente oculta** para evitar poluição visual e lentidão ao navegar em projetos JavaScript/TypeScript.

### 2. ⚡ Otimizações de Performance (`lua/plugins/performance.lua` e `lua/config/`)
Projetado para eliminar travamentos (*stuttering*) e *input lag* em processadores dual-core (ex: Intel Celeron / Core 2 Duo / i3 antigos):

- **LSP e Diagnósticos:**
  - **Semantic Tokens Desativados:** O Treesitter já realiza o realce de sintaxe com rapidez nativa. Desativar semantic tokens do LSP elimina requisições pesadas aos servidores de linguagem (como OmniSharp e TypeScript/vtsls) a cada caractere digitado.
  - **Inlay Hints Desativados:** Evita o recálculo contínuo e renderização de textos virtuais inline em background.
  - **Diagnósticos Pausados no Modo Insert (`update_in_insert = false`):** Diagnósticos são recalculados apenas ao retornar ao modo Normal, liberando a CPU enquanto você digita.
- **Renderização e Redraws da UI:**
  - **Cursorline Dinâmico:** A linha destacada do cursor é desativada automaticamente no modo de inserção (`InsertEnter`) e reativada no modo normal (`InsertLeave`), eliminando a repintura da tela inteira a cada tecla.
  - **Animações Desativadas:** Desativadas animações de *scroll* e linhas de indentação no `snacks.nvim` e `mini.animate`.
  - **Sem Spinners no Noice (`lsp.progress.enabled = false`):** Evita janelas flutuantes com animações a 60fps durante compilações ou indexações do LSP.
  - **Interface Estável:** `signcolumn = "yes"` fixo (evita saltos e recálculo de largura da janela), `showcmd = false` e `ruler = false`.
- **Treesitter & Autocompletar (Blink.cmp):**
  - **Indentação do Treesitter Desativada:** Mantém a indentação nativa do Neovim, eliminando o atraso ao teclar <kbd>Enter</kbd> ou <kbd>Tab</kbd>.
  - **Proteção para Arquivos Grandes:** Desativação automática do Treesitter para arquivos > 100 KB.
  - **Blink.cmp Otimizado:** Sem parser do Treesitter nos itens do menu dropdown (`draw = { treesitter = {} }`) e delay da janela de documentação ajustado para 400ms para digitação ágil.
- **Git & Statusline:**
  - **Gitsigns:** *Debounce* de cálculo de diffs aumentado para 400ms e limite máximo de 5000 linhas.
  - **Lualine:** Taxa de atualização aliviada para 500ms.

### 3. 🎨 Tema e Visual (`lua/plugins/colorscheme.lua`)
- **Catppuccin Mocha** definido como tema padrão.
- Integrações de cores ativas e consistentes para: *Blink.cmp*, *Gitsigns*, *Noice*, *Snacks*, *Treesitter*, *Which-Key* e *Mason*.

### 4. 📦 Linguagens e Extras Ativos (`lazyvim.json`)
- **TypeScript / JavaScript:** Suporte a vtsls/tsserver, JSX/TSX.
- **Tailwind CSS:** Autocomplete e realce de classes utilitárias.
- **Prisma ORM:** Realce de sintaxe e LSP para esquemas do Prisma.
- **.NET / C#:** Suporte a C# com OmniSharp estendido.
- **Prettier:** Formatação automática consistente.

---

## ⌨️ Atalhos Principais

| Atalho | Descrição |
| :--- | :--- |
| `<leader>e` ou `<leader>fe` | Abre o explorador de arquivos (Snacks Explorer) |
| `<leader>ff` | Buscar arquivos no projeto |
| `<leader>sg` / `<leader>/` | Busca por texto no projeto (Grep) |
| `<leader>bd` | Fechar buffer atual |
| `<leader>w` | Salvar arquivo |
| `<leader>q` | Sair do Neovim |
| `<leader>cm` | Gerenciador Mason (LSPs, Linters, Formatters) |
| `<leader>l` | Gerenciador Lazy.nvim |
