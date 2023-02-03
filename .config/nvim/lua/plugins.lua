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
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				background = {
					light = "latte",
					dark = "mocha",
				},
				transparent_background = true,
				term_colors = true,
			})
			vim.cmd([[colorscheme catppuccin]])
		end,
	},
	-- }}}

	-- Completions {{{
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-emoji",
			"andersevenrud/cmp-tmux",
			"lukas-reineke/cmp-rg",
			"octaltree/cmp-look",
		},
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				mapping = cmp.mapping.preset.insert({
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "c" }),
					["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "c" }),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "nvim_lua" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "cmdline" },
					{ name = "emoji" },
					{ name = "tmux", keyword_length = 2, option = { trigger_characters = {}, all_panes = true } },
					{ name = "rg" },
					{ name = "look", keyword_length = 2, option = { convert_case = true, loud = true } },
				}),
			})
		end,
	},
	-- }}}

	-- Editing {{{
	{ "kana/vim-operator-user" },
	{
		"kana/vim-operator-replace",
		config = function()
			vim.cmd("map R <Plug>(operator-replace)")
		end,
	},
	{ "tpope/vim-surround" },
	{ "tpope/vim-repeat" },
	{ "tpope/vim-abolish" },
	{ "vim-scripts/Align" },
	{
		"junegunn/vim-easy-align",
		config = function()
			vim.cmd([[
              xmap ga <Plug>(EasyAlign)
              nmap ga <Plug>(EasyAlign)
            ]])
		end,
	},
	{ "jiangmiao/auto-pairs" },
	{ "simeji/winresizer" },
	{
		"wesQ3/vim-windowswap",
		config = function()
			vim.cmd([[
              let g:windowswap_map_keys = 0 
              nnoremap <silent> <leader>ww :call WindowSwap#EasyWindowSwap()<CR>
            ]])
		end,
	},
	-- }}}
})
