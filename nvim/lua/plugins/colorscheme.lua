return {
  -- Configuração do tema Catppuccin
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      flavour = "mocha",
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
      },
      integrations = {
        blink_cmp = true,
        cmp = true,
        gitsigns = true,
        indent_blankline = { enabled = true },
        mason = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        neo_tree = true,
        noice = true,
        notify = true,
        render_markdown = true,
        snacks = true,
        telescope = true,
        treesitter = true,
        which_key = true,
      },
    },
  },

  -- Definir Catppuccin Mocha como tema padrão do LazyVim
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
