return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit (Status)" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit (Commit)" },
      { "<leader>gp", "<cmd>Neogit pull<cr>", desc = "Neogit (Pull)" },
      { "<leader>gP", "<cmd>Neogit push<cr>", desc = "Neogit (Push)" },
      { "<leader>gb", "<cmd>Neogit branch<cr>", desc = "Neogit (Branch)" },
    },
    opts = {
      graph_style = "unicode",
      integrations = {
        diffview = true,
      },
    },
  },
}
