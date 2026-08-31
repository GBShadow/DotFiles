-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Permite colar repetidas vezes sobre seleções no modo visual sem sobrescrever o registrador de cópia
vim.keymap.set("x", "p", [["_dP]], { desc = "Paste without overwriting register" })
