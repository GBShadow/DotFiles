-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Otimizações para hardware modesto (CPU dual-core / GPU integrada)
vim.g.snacks_animate = false -- Desativa animações globais do Snacks antes do carregamento
vim.opt.synmaxcol = 240 -- Não processar syntax highlighting em colunas muito longas (evita travamentos em minificados)
vim.opt.updatetime = 300 -- Reduz frequência de I/O em disco e updates de cursor
vim.opt.timeoutlen = 300 -- Tempo de espera de atalhos mais ágil
vim.opt.redrawtime = 1500 -- Limite máximo de tempo gasto renderizando sintaxe por tela
vim.opt.smoothscroll = false -- Desativa rolagem suave que pode causar stuttering em GPUs antigas
vim.opt.showcmd = false -- Não redesenha status ao digitar comandos parciais
vim.opt.ruler = false -- Lualine já exibe posição da linha/coluna
vim.opt.signcolumn = "yes" -- Coluna de sinais fixa para evitar recálculo de layout da janela
vim.opt.swapfile = false -- Reduz escritas desnecessárias no disco
