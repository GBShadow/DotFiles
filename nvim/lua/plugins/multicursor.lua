return {
  -- 1. Multi-seleção com múltiplos cursores (estilo VSCode: Ctrl+d, Ctrl+Shift+l)
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      -- Mapeamentos estilo VSCode
      vim.g.VM_maps = {
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
        ["Select All"] = "<C-S-l>",
        ["Visual All"] = "<C-S-l>",
        ["Select Cursor Down"] = "<C-Down>",
        ["Select Cursor Up"] = "<C-Up>",
      }

      -- Sensibilidade de caixa: 'smart' (case sensitive se tiver maiúscula), 'sensitive' ou 'ignore'
      vim.g.VM_case_setting = "smart"

      -- Ativa mapeamentos padrão adicionais do VM
      vim.g.VM_default_mappings = 1
    end,
  },

  -- 2. Preservação de Case em substituições (Preserve Case estilo VSCode)
  -- Permite usar :%Subvert/teste/texto/g (ou :%S/teste/texto/g)
  -- Substitui mantendo: teste -> texto, Teste -> Texto, TESTE -> TEXTO
  {
    "tpope/vim-abolish",
    event = "VeryLazy",
  },

  -- 3. Renomeação semântica com preview em tempo real (F2 estilo VSCode)
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {},
  },

  -- Integração do inc-rename com o Noice para janela flutuante com preview
  {
    "folke/noice.nvim",
    optional = true,
    opts = {
      presets = { inc_rename = true },
    },
  },
}
