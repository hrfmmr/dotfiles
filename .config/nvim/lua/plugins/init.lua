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
		event = "VimEnter",
	},
	-- }}}

	-- Completions {{{
	{
		"hrsh7th/nvim-cmp",
		dependencies = require("plugins.config.nvim-cmp").dependencies,
		config = require("plugins.config.nvim-cmp").config,
		event = "InsertEnter",
	},
	{ "hrsh7th/cmp-nvim-lsp", event = "InsertEnter" },
	{ "hrsh7th/cmp-nvim-lua", event = "InsertEnter" },
	{ "hrsh7th/cmp-buffer", event = "InsertEnter" },
	{ "hrsh7th/cmp-path", event = "InsertEnter" },
	{ "hrsh7th/cmp-cmdline", event = "ModeChanged" },
	{ "hrsh7th/cmp-emoji", event = "InsertEnter" },
	{ "andersevenrud/cmp-tmux", event = "InsertEnter" },
	{ "lukas-reineke/cmp-rg", event = "InsertEnter" },
	{ "quangnguyen30192/cmp-nvim-ultisnips", event = "InsertEnter" },
	-- }}}

	-- Editing {{{
	{
		"kana/vim-operator-replace",
		dependencies = require("plugins.config.operator-replace").dependencies,
		config = require("plugins.config.operator-replace").config,
		-- event = "VeryLazy",
	},
	{ "tpope/vim-surround" },
	{ "tpope/vim-repeat" },
	{ "tpope/vim-abolish" },
	{ "vim-scripts/Align" },
	{
		"junegunn/vim-easy-align",
		config = require("plugins.config.easy-align"),
		-- event = "VeryLazy",
	},
	{
		"windwp/nvim-autopairs",
		config = require("plugins.config.nvim-autopairs"),
	},
	{
		"simeji/winresizer",
		config = require("plugins.config.winresizer"),
		-- event = "VeryLazy",
	},
	{
		"wesQ3/vim-windowswap",
		config = require("plugins.config.windowswap"),
		-- event = "VeryLazy",
	},
	{
		"scrooloose/nerdcommenter",
		init = require("plugins.config.nerdcommenter").init,
		config = require("plugins.config.nerdcommenter").config,
		-- event = "VeryLazy",
	},
	{
		"previm/previm",
		config = require("plugins.config.previm"),
		-- event = "VeryLazy",
	},
	{
		"easymotion/vim-easymotion",
		config = require("plugins.config.easymotion"),
		-- event = "VeryLazy",
	},
	{
		"kevinhwang91/nvim-bqf",
		dependencies = require("plugins.config.nvim-bqf").dependencies,
		config = require("plugins.config.nvim-bqf").config,
	},
	{
		"gbprod/yanky.nvim",
		dependencies = require("plugins.config.yanky").dependencies,
		opts = require("plugins.config.yanky").opts,
		config = require("plugins.config.yanky").config,
	},
	-- }}}

	-- {{{ Snippets
	{
		"SirVer/ultisnips",
		dependencies = require("plugins.config.ultisnips").dependencies,
		config = require("plugins.config.ultisnips").config,
		-- event = "InsertEnter",
	},
	-- }}}

	-- Fuzzy Finder {{{
	{
		"nvim-telescope/telescope.nvim",
		dependencies = require("plugins.config.telescope").dependencies,
		config = require("plugins.config.telescope").config,
		-- event = "BufWinEnter",
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
		-- event = "BufWinEnter",
	},
	{
		"nvim-telescope/telescope-frecency.nvim",
		dependencies = { "kkharji/sqlite.lua" },
		-- event = "BufWinEnter",
	},
	-- }}}

	-- Navigation {{{
	{ "vim-airline/vim-airline", event = "VeryLazy" },
	{
		"scrooloose/nerdtree",
		config = require("plugins.config.nerdtree"),
		-- event = "BufWinEnter",
	},
	{
		"majutsushi/tagbar",
		config = require("plugins.config.tagbar"),
		-- event = { "BufNewFile", "BufRead" },
	},
	-- }}}

	-- git {{{
	{
		"tpope/vim-fugitive",
		config = require("plugins.config.fugitive"),
		event = "VeryLazy",
	},
	{ "tpope/vim-rhubarb", dependencies = {
		"tpope/vim-fugitive",
	}, event = "VeryLazy" },
	{ "tpope/vim-dispatch", event = "VeryLazy" },
	{
		"rbong/vim-flog",
		config = require("plugins.config.flog"),
		event = "VeryLazy",
	},
	{
		"sindrets/diffview.nvim",
		dependencies = require("plugins.config.diffview").dependencies,
		config = require("plugins.config.diffview").config,
		event = "VeryLazy",
	},
	{
		"lewis6991/gitsigns.nvim",
		config = require("plugins.config.gitsigns"),
		event = { "BufNewFile", "BufRead" },
	},
	{
		"pwntester/octo.nvim",
		dependencies = require("plugins.config.octo").dependencies,
		config = require("plugins.config.octo").config,
		event = "VeryLazy",
	},
	{
		"rhysd/ghpr-blame.vim",
		config = require("plugins.config.ghpr-blame"),
		event = "VeryLazy",
	},
	-- }}}

	-- Language & Syntax {{{
	{
		"nvim-treesitter/nvim-treesitter",
		config = require("plugins.config.treesitter"),
		-- event = "VeryLazy",
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
	{ "chr4/nginx.vim", event = { "BufNewFile", "BufRead" } },
	-- plantuml
	{
		"aklt/plantuml-syntax",
		config = require("plugins.config.plantuml-syntax"),
		event = { "BufNewFile", "BufRead" },
	},
	-- tmux
	{ "tmux-plugins/vim-tmux", event = { "BufNewFile", "BufRead" } },
	-- terraform
	{
		"hashivim/vim-terraform",
		config = require("plugins.config.vim-terraform"),
		event = { "BufNewFile", "BufRead" },
	},
	-- jsonnet
	{
		"google/vim-jsonnet",
		event = { "BufNewFile", "BufRead" },
	},
	-- }}}

	-- LSP {{{
	{
		"williamboman/mason.nvim",
		config = require("plugins.config.mason"),
		-- event = "VeryLazy",
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = require("plugins.config.mason-lspconfig").dependencies,
		config = require("plugins.config.mason-lspconfig").config,
		-- event = "VeryLazy",
	},
	{
		"neovim/nvim-lspconfig",
		config = require("plugins.config.nvim-lspconfig"),
		-- event = "VeryLazy",
	},
	{
		"nvimtools/none-ls.nvim",
		dependencies = { "nvimtools/none-ls-extras.nvim" },
		config = require("plugins.config.null-ls"),
		-- event = "VeryLazy",
	},

	-- Diagnostics {{{
	{
		"folke/trouble.nvim",
		dependencies = require("plugins.config.trouble").dependencies,
		config = require("plugins.config.trouble").config,
		-- event = "BufWinEnter",
	},
	-- }}}

	-- Runner {{{
	{
		"Shougo/vimproc.vim",
		build = "make",
		-- event = "VeryLazy",
	},
	{
		"thinca/vim-quickrun",
		dependencies = require("plugins.config.quickrun").dependencies,
		config = require("plugins.config.quickrun").config,
		-- event = "VeryLazy",
	},
	-- }}}

	-- Testing {{{
	{
		"janko/vim-test",
		config = require("plugins.config.vim-test"),
		event = "VeryLazy",
	},
	-- }}}
})
