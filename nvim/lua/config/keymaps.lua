-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Permite colar repetidas vezes sobre seleções no modo visual sem sobrescrever o registrador de cópia
vim.keymap.set("x", "p", [["_dP]], { desc = "Paste without overwriting register" })

-- Atalho rápido para ver diagnóstico/erro completo da linha em janela flutuante com quebra de texto
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Line Diagnostics (Float)" })

-- F2: Renomeia símbolo (variável, função, classe, etc.) em todo o projeto (estilo VSCode)
vim.keymap.set("n", "<F2>", function()
  local ok, inc_rename = pcall(require, "inc_rename")
  if ok then
    return ":IncRename " .. vim.fn.expand("<cword>")
  else
    vim.lsp.buf.rename()
    return ""
  end
end, { expr = true, desc = "Rename symbol in project (F2)" })

-- Ctrl + h: Localizar e substituir no arquivo atual (estilo VSCode)
vim.keymap.set({ "n", "x" }, "<C-h>", function()
  local grug = require("grug-far")
  local current_file = vim.bo.buftype == "" and vim.fn.expand("%") or nil
  grug.open({
    transient = true,
    prefills = {
      paths = current_file,
      search = vim.fn.mode() == "v" and grug.get_current_visual_selection() or vim.fn.expand("<cword>"),
    },
  })
end, { desc = "Find & Replace in current file (VSCode Ctrl+H)" })
-- Substituição preservando Case (Preserve Case com vim-abolish: teste->texto, Teste->Texto, TESTE->TEXTO)
vim.keymap.set("n", "<leader>rp", function()
  local cword = vim.fn.expand("<cword>")
  local keys = vim.api.nvim_replace_termcodes(":%S/" .. cword .. "//gw<Left><Left><Left>", true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Replace preserving Case (:Subvert)" })

-- Multi-cursor: atalhos para Select All (Ctrl+Shift+L) e alternativa <leader>ma caso o terminal não envie Shift
vim.keymap.set("n", "<C-S-l>", "<Plug>(VM-Select-All)", { desc = "Multi-cursor: Select All (Normal)" })
vim.keymap.set("x", "<C-S-l>", "<Plug>(VM-Visual-All)", { desc = "Multi-cursor: Select All (Visual)" })
vim.keymap.set("n", "<C-S-L>", "<Plug>(VM-Select-All)", { desc = "Multi-cursor: Select All (Normal)" })
vim.keymap.set("x", "<C-S-L>", "<Plug>(VM-Visual-All)", { desc = "Multi-cursor: Select All (Visual)" })
vim.keymap.set("n", "<leader>ma", "<Plug>(VM-Select-All)", { desc = "Multi-cursor: Select All" })
vim.keymap.set("x", "<leader>ma", "<Plug>(VM-Visual-All)", { desc = "Multi-cursor: Select All" })
