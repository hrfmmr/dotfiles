-- Basic
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.lazyredraw = true
vim.opt.clipboard = "unnamedplus"

-- GUI
vim.opt.cmdheight = 2
vim.opt.list = true

-- Backup
vim.opt.backup = true
vim.opt.backupdir = os.getenv("HOME") .. ".vim/backup"
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
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.backspace = "indent,eol,start"
vim.opt.whichwrap = "b,s,h,l,<,>,[,]"
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
