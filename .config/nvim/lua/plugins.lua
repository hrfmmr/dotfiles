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
	{
		"kana/vim-operator-replace",
		dependencies = {
			"kana/vim-operator-user",
		},
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

	-- Explorer {{{
	{
		"scrooloose/nerdtree",
		config = function()
			vim.cmd([[
              nnoremap [nerdtree] <Nop>
              nmap <Leader>e [nerdtree]
              nnoremap <silent> [nerdtree]c :NERDTreeFind<CR>
              nnoremap <silent> [nerdtree]n :NERDTreeToggle<CR>
              nnoremap <silent> [nerdtree]r :NERDTree .<CR>
            ]])
		end,
	},
	{
		"junegunn/fzf.vim",
		dependencies = {
			"junegunn/fzf",
		},
		config = function()
			vim.cmd([[
              set rtp+=~/.fzf

              function! RipgrepFzf(query, fullscreen)
                let command_fmt = 'rg --ignore-file ~/.ignore --hidden --column --line-number --no-heading --color=always --smart-case -- %s || true'
                let initial_command = printf(command_fmt, shellescape(a:query))
                let reload_command = printf(command_fmt, '{q}')
                let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
                call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
              endfunction

              command! -nargs=* -bang RG 
                \ call RipgrepFzf(<q-args>, <bang>0)

              nnoremap <silent> <C-u><C-u> :Files<CR>
              nnoremap <silent> <C-u><C-b> :Buffers<CR>
              nnoremap <silent> <C-u><C-g> :RG <C-R><C-W><CR>
              nnoremap <silent> <C-u><C-h> :History<CR>
              nnoremap <silent> <C-u><C-l> :Lines<CR>
              nnoremap <silent> <C-u><C-r> :BLines<CR>
              nnoremap <silent> <C-u><C-s> :GFiles?<CR>
              nnoremap <silent> <C-u><C-t> :Filetypes<CR>
              nnoremap <silent> <C-u><C-n> :Snippets<CR>
            ]])
		end,
	},
	-- }}}
})
