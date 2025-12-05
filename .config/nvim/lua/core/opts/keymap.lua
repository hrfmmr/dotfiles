-- global
vim.g.mapleader = ","
vim.g.maplocalleader = "<Space>"
vim.keymap.set("i", "<C-c>", "<ESC>")
vim.keymap.set("", "s", "<Nop>")
vim.keymap.set("n", "<Leader>R", function()
	require("utils").reloadConfig()
end, { desc = "Reload nvim config" })

-- insert new line
vim.keymap.set("n", "<CR>", "i<CR><ESC>")
vim.keymap.set("n", "[e", "gT", { desc = "Previous tab" })
vim.keymap.set("n", "]e", "gt", { desc = "Next tab" })
-- Move tab
vim.keymap.set("n", "[E", ":-tabm<CR>", { silent = true, desc = "Move tab left" })
vim.keymap.set("n", "]E", ":+tabm<CR>", { silent = true, desc = "Move tab right" })
-- Emacs key bind for moving cursole while INSERT
vim.keymap.set("i", "<c-n>", "<down>")
vim.keymap.set("i", "<c-p>", "<up>")
vim.keymap.set("i", "<c-b>", "<left>")
vim.keymap.set("i", "<c-f>", "<right>")
vim.keymap.set("i", "<c-a>", "<Esc>_i")
vim.keymap.set("i", "<c-e>", "<Esc>$a")
-- Split window
vim.keymap.set("n", "<Space>V", ":new<CR>", { silent = true })
vim.keymap.set("n", "<Space>H", ":vne<CR>", { silent = true })
-- Switch window
vim.keymap.set("n", "<c-j>", "<c-w>j")
vim.keymap.set("n", "<c-k>", "<c-w>k")
vim.keymap.set("n", "<c-l>", "<c-w>l")
vim.keymap.set("n", "<c-h>", "<c-w>h")
-- Paging
vim.keymap.set("n", "<Space>j", "<c-f>")
vim.keymap.set("n", "<Space>k", "<c-b>")
-- File write/quit/update
vim.keymap.set("n", "<Space>w", ":w<CR>", { silent = true })
vim.keymap.set("n", "<Space>q", ":q<CR>", { silent = true })
vim.keymap.set("n", "<Space>Q", ":bd!<CR>", { silent = true })
vim.keymap.set("n", "<Space>e", ":e!<CR>", { silent = true })
-- Tab Handling
vim.keymap.set("n", "<leader>te", ":<C-u>tabedit<CR>", { silent = true })
vim.keymap.set("n", "<leader>tc", ":tab<space>split<CR>", { silent = true })
-- Search visual selected
vim.keymap.set("v", "//", 'y/<C-R>"<CR>')
-- quickfix
vim.keymap.set("n", "[q", ":cprevious<CR>", { silent = true })
vim.keymap.set("n", "]q", ":cnext<CR>", { silent = true })
vim.keymap.set("n", "[Q", ":<C-u>cfirst<CR>", { silent = true })
vim.keymap.set("n", "]Q", ":<C-u>clast<CR>", { silent = true })
vim.keymap.set("n", "[<C-q>", ":<C-u>cpfile<CR>", { silent = true })
vim.keymap.set("n", "]<C-q>", ":<C-u>cnfile<CR>", { silent = true })
vim.keymap.set("n", "<Leader>ff", require("utils").toggleQuickfix)
-- term
vim.keymap.set("n", "<C-t>", ":term<CR>", { silent = true })
vim.keymap.set("t", "<C-q>", "<C-\\><C-n>")
