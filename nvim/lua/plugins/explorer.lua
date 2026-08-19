return {
  -- Configuração do explorador de arquivos (Snacks Explorer - padrão do LazyVim)
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true, -- Não esconde arquivos que começam com ponto (ex: .gitignore, .env)
            ignored = true, -- Não esconde itens definidos no .gitignore
            exclude = { "node_modules" }, -- Mantém a pasta node_modules oculta
          },
        },
      },
    },
  },

  -- Configuração para Neo-tree (caso esteja ativo ou venha a ser ativado)
  {
    "nvim-neo-tree/neo-tree.nvim",
    optional = true,
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false, -- Mostra arquivos que começam com ponto
          hide_gitignored = false, -- Mostra arquivos ignorados pelo .gitignore
          hide_by_name = {
            "node_modules",
          },
          never_show = {
            "node_modules",
          },
        },
      },
    },
  },
}
