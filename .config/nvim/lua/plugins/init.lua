local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

	-- Colorscheme {{{
	{
		"catppuccin/nvim",
		name = "catppuccin",
		config = require("plugins.config.catppuccin"),
	},
	-- }}}

	-- Completions {{{
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = require("plugins.config.nvim-cmp").dependencies,
		config = require("plugins.config.nvim-cmp").config,
	},
	-- }}}

	-- Editing {{{
	{
		"kana/vim-operator-replace",
		dependencies = require("plugins.config.operator-replace").dependencies,
		config = require("plugins.config.operator-replace").config,
	},
	{ "tpope/vim-surround" },
	{ "tpope/vim-repeat" },
	{ "tpope/vim-abolish" },
	{ "vim-scripts/Align" },
	{
		"junegunn/vim-easy-align",
		config = require("plugins.config.easy-align"),
	},
	{
		"jiangmiao/auto-pairs",
		config = require("plugins.config.auto-pairs"),
	},
	{
		"simeji/winresizer",
		config = require("plugins.config.winresizer"),
	},
	{
		"wesQ3/vim-windowswap",
		config = require("plugins.config.windowswap"),
	},
	{
		"scrooloose/nerdcommenter",
		init = require("plugins.config.nerdcommenter").init,
		config = require("plugins.config.nerdcommenter").config,
	},
	{
		"previm/previm",
		config = require("plugins.config.previm"),
	},
	{
		"easymotion/vim-easymotion",
		config = require("plugins.config.easymotion"),
	},
	-- }}}

	-- {{{ Snippets
	{
		"SirVer/ultisnips",
		dependencies = require("plugins.config.ultisnips").dependencies,
		config = require("plugins.config.ultisnips").config,
	},
	-- }}}

	-- Fuzzy Finder {{{
	{
		"nvim-telescope/telescope.nvim",
		dependencies = require("plugins.config.telescope").dependencies,
		config = require("plugins.config.telescope").config,
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
	},
	{
		"nvim-telescope/telescope-frecency.nvim",
		dependencies = { "kkharji/sqlite.lua" },
	},
	-- }}}

	-- UI {{{
	{
		"vim-airline/vim-airline",
	},
	{
		"scrooloose/nerdtree",
		config = require("plugins.config.nerdtree"),
	},
	{
		"majutsushi/tagbar",
		config = require("plugins.config.tagbar"),
	},
	-- }}}

	-- git {{{
	{
		"tpope/vim-fugitive",
		config = require("plugins.config.fugitive"),
	},
	{ "tpope/vim-rhubarb", dependencies = {
		"tpope/vim-fugitive",
	} },
	{ "tpope/vim-dispatch" },
	{
		"rbong/vim-flog",
		config = require("plugins.config.flog"),
	},
	{
		"sindrets/diffview.nvim",
		dependencies = require("plugins.config.diffview").dependencies,
		config = require("plugins.config.diffview").config,
	},
	{
		"lewis6991/gitsigns.nvim",
		config = require("plugins.config.gitsigns"),
	},
	{
		"pwntester/octo.nvim",
		dependencies = require("plugins.config.octo").dependencies,
		config = require("plugins.config.octo").config,
	},
	-- }}}

	-- Language & Syntax {{{
	{
		"nvim-treesitter/nvim-treesitter",
		config = require("plugins.config.treesitter"),
	},
	{
		-- go
		"fatih/vim-go",
		config = require("plugins.config.vim-go"),
		ft = "go",
	},
	-- rust
	{
		"rust-lang/rust.vim",
		ft = "rust",
	},
	-- html
	{
		"valloric/MatchTagAlways",
		ft = "html",
	},
	-- markdown
	{
		"plasticboy/vim-markdown",
		dependencies = require("plugins.config.vim-markdown").dependencies,
		config = require("plugins.config.vim-markdown").config,
    ft = "markdown",
	},
	-- nginx
	{ "chr4/nginx.vim" },
	-- plantuml
	{
		"aklt/plantuml-syntax",
		config = require("plugins.config.plantuml-syntax"),
	},
	-- tmux
	{ "tmux-plugins/vim-tmux" },
	-- terraform
	{
		"hashivim/vim-terraform",
		config = require("plugins.config.vim-terraform"),
	},
	-- jsonnet
	{
		"google/vim-jsonnet",
	},
	-- sql
	{
		"nanotee/sqls.nvim",
		config = require("plugins.config.sqls"),
		ft = "sql",
	},
	-- }}}

	-- LSP {{{
	{
		"williamboman/mason.nvim",
		config = require("plugins.config.mason"),
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = require("plugins.config.mason-lspconfig").dependencies,
		config = require("plugins.config.mason-lspconfig").config,
	},
	{
		"neovim/nvim-lspconfig",
		config = require("plugins.config.nvim-lspconfig"),
	},
	{
		"jose-elias-alvarez/null-ls.nvim",
		config = require("plugins.config.null-ls"),
	},

	-- Diagnostics {{{
	{
		"folke/trouble.nvim",
		dependencies = require("plugins.config.trouble").dependencies,
		config = require("plugins.config.trouble").config,
	},
	-- }}}

	-- Runner {{{
	{
		"Shougo/vimproc.vim",
		build = "make",
	},
	{
		"thinca/vim-quickrun",
		dependencies = require("plugins.config.quickrun").dependencies,
		config = require("plugins.config.quickrun").config,
	},
	-- }}}

	-- Testing {{{
	{
		"janko/vim-test",
		config = require("plugins.config.vim-test"),
	},
	-- }}}
})
