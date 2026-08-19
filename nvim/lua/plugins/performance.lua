return {
  -- Otimizações para o LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = false, -- Desativa inlay hints automáticos (economiza muitas requisições ao LSP)
      },
      diagnostics = {
        underline = true,
        update_in_insert = false, -- NÃO recalcular diagnósticos enquanto digita (poupa CPU)
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
      },
    },
    init = function()
      -- Desativa semantic tokens para todos os LSPs (o Treesitter já faz o highlight sintático de forma mais rápida)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities then
            client.server_capabilities.semanticTokensProvider = nil
          end
        end,
      })
    end,
  },

  -- Otimização do Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false, -- Desativa regex legado do Vim para não duplicar processamento
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall((vim.uv or vim.loop).fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
      },
      indent = {
        enable = false, -- Desativa indentação via Treesitter (evita atraso perceptível ao teclar Enter/Tab em CPUs de 2 núcleos)
      },
    },
  },

  -- Otimização de UI / Snacks (desativar animações pesadas de scroll e indent)
  {
    "folke/snacks.nvim",
    opts = {
      animate = { enabled = false }, -- Desativa animações globais do Snacks
      scroll = { enabled = false }, -- Desativa smooth scroll (evita lag de renderização)
      indent = {
        enabled = true,
        animate = { enabled = false }, -- Desativa animação das linhas de indentação
      },
    },
  },

  -- Desativa animações contínuas de progresso do LSP no Noice (poupa redraws constantes a 60fps em compilações do OmniSharp/TS)
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        progress = {
          enabled = false, -- Evita popup com spinner animado gerando constantes redraws
        },
      },
    },
  },

  -- Otimização do Gitsigns (reduz frequência de cálculo de diffs durante a digitação)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      update_debounce = 400, -- Aguarda 400ms de inatividade para recalcular git signs
      max_file_length = 5000, -- Desativa gitsigns em arquivos muito grandes (>5000 linhas)
    },
  },

  -- Otimização da Lualine (diminui a taxa de atualização da barra de status)
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        refresh = {
          statusline = 500, -- Atualiza a cada 500ms em vez de 100ms
          tabline = 500,
          winbar = 500,
        },
      },
    },
  },

  -- Desativa mini.animate caso seja carregado por algum extra
  {
    "nvim-mini/mini.animate",
    enabled = false,
  },

  -- Otimização do sistema de autocompletar (Blink.cmp)
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      completion = {
        ghost_text = {
          enabled = false, -- Desativa ghost text no autocomplete para economizar renderizações
        },
        menu = {
          draw = {
            treesitter = {}, -- Não roda parser do treesitter para colorir cada item do menu
          },
        },
        documentation = {
          auto_show_delay_ms = 400, -- Evita abrir popups de documentação instantaneamente enquanto você ainda está digitando rápido
        },
      },
    },
  },
}
