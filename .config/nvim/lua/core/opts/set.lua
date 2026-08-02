-- Basic
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.lazyredraw = true
vim.opt.clipboard = "unnamedplus"

-- Providers
-- Pin the python3 host to a dedicated venv so runtime version bumps (mise, brew)
-- never leave the provider pointing at an interpreter without pynvim.
-- stdpath("data") keeps this in sync with the setup script's XDG_DATA_HOME handling.
local python3_host = vim.fn.stdpath("data") .. "/venv/bin/python3"
if (vim.uv or vim.loop).fs_stat(python3_host) then
	vim.g.python3_host_prog = python3_host
end

-- GUI
vim.opt.cmdheight = 2
vim.opt.list = true

-- Backup
vim.opt.backup = true
vim.opt.backupdir = os.getenv("HOME") .. "/.vim/backup"
vim.opt.swapfile = false
vim.opt.undofile = false

-- File
vim.opt.hidden = true
vim.opt.autoread = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrapscan = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- Indent
vim.opt.expandtab = true
vim.opt.smarttab = true
-- vim.opt.autoindent = true
-- vim.opt.smartindent = true
vim.opt.cindent = true
vim.opt.backspace = "indent,eol,start"
vim.opt.whichwrap = "b,s,h,l,<,>,[,]"
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
