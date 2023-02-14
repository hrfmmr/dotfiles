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
			vim.cmd(
				"highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE"
			)
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
			-- "octaltree/cmp-look",
		},
		config = function()
			local cmp = require("cmp")
			vim.o.completeopt = "menuone,noselect"
			local t = function(str)
				return vim.api.nvim_replace_termcodes(str, true, true, true)
			end
			local check_back_space = function()
				local col = vim.fn.col(".") - 1
				return col == 0 or vim.fn.getline("."):sub(col, col):match("%s") ~= nil
			end
			cmp.setup({
				snippet = {
					expand = function(args)
						vim.fn["UltiSnips#Anon"](args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "c" }),
					["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "c" }),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-e>"] = cmp.mapping.complete(),
					["<C-q>"] = cmp.mapping.abort(),
					-- expand snippet
					["<C-y>"] = cmp.mapping(function(fallback)
						if vim.fn["UltiSnips#CanExpandSnippet"]() == 1 then
							vim.fn.feedkeys(t("<C-R>=UltiSnips#ExpandSnippet()<CR>"))
						elseif check_back_space() then
							vim.fn.feedkeys(t("<C-e>"), "n")
						else
							fallback()
						end
					end, { "i", "s" }),

					-- cycle menu, jump through tabstop
					["<Tab>"] = cmp.mapping(function(fallback)
						if vim.fn["UltiSnips#CanJumpForwards"]() == 1 then
							vim.fn.feedkeys(t("<ESC>:call UltiSnips#JumpForwards()<CR>"))
						elseif vim.fn.pumvisible() == 1 then
							vim.fn.feedkeys(t("<C-n>"), "n")
						elseif check_back_space() then
							vim.fn.feedkeys(t("<tab>"), "n")
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if vim.fn["UltiSnips#CanJumpBackwards"]() == 1 then
							return vim.fn.feedkeys(t("<C-R>=UltiSnips#JumpBackwards()<CR>"))
						elseif vim.fn.pumvisible() == 1 then
							vim.fn.feedkeys(t("<C-p>"), "n")
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "nvim_lua" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "emoji" },
					{ name = "tmux", keyword_length = 2, option = { trigger_characters = {}, all_panes = true } },
					{ name = "rg", keyword_length = 3 },
					-- { name = "look", keyword_length = 2, option = { convert_case = true, loud = true } },
				}),
			})
		end,
	},
	{
		"hrsh7th/cmp-cmdline",
		config = function()
			local cmp = require("cmp")
			-- Completions for command mode
			-- `:` cmdline setup.
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{
						name = "cmdline",
						option = {
							ignore_cmds = { "Man", "!" },
						},
					},
				}),
			})
			-- Completions for / search based on current buffer
			-- `/` cmdline setup.
			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
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
	{
		"jiangmiao/auto-pairs",
		config = function()
			vim.cmd([[
                autocmd! Filetype TelescopePrompt let b:autopairs_enabled = 0
            ]])
		end,
	},
	{
		"simeji/winresizer",
		config = function()
			vim.cmd([[
                let g:winresizer_start_key = '<C-e><C-w>'
            ]])
		end,
	},
	{
		"wesQ3/vim-windowswap",
		config = function()
			vim.cmd([[
              let g:windowswap_map_keys = 0 
              nnoremap <silent> <leader>ww :call WindowSwap#EasyWindowSwap()<CR>
            ]])
		end,
	},
	{
		"scrooloose/nerdcommenter",
		init = function()
			vim.cmd("let g:NERDCreateDefaultMappings = 0")
		end,
		config = function()
			vim.cmd([[
              let g:NERDSpaceDelims = 1
              nmap <Space>/ <Plug>NERDCommenterToggle
              vmap <Space>s <Plug>NERDCommenterSexy
            ]])
		end,
	},
	{
		"previm/previm",
		config = function()
			vim.cmd([[
                let g:previm_open_cmd = 'open -a "Google Chrome"'
                nmap <Leader>P :PrevimOpen<CR>
            ]])
		end,
	},
	{
		"easymotion/vim-easymotion",
		config = function()
			vim.cmd([[
                let g:EasyMotion_do_mapping = 0
                let g:EasyMotion_keys = ';a,oqepughtcrnwv'
                let g:EasyMotion_smartcase = 1
                nmap s <Plug>(easymotion-s2)
                xmap s <Plug>(easymotion-s2)
                nmap <Leader>s <Plug>(easymotion-sn)
                xmap <Leader>s <Plug>(easymotion-sn)
                map <Leader>j <Plug>(easymotion-j)
                map <Leader>k <Plug>(easymotion-k)
                let g:EasyMotion_enter_jump_first = 1
                let g:EasyMotion_space_jump_first = 1
                let g:EasyMotion_startofline = 0
            ]])
		end,
	},
	-- }}}

	-- {{{ Snippets
	{
		"SirVer/ultisnips",
		dependencies = {
			"honza/vim-snippets",
		},
		config = function()
			vim.cmd([[
              let g:UltiSnipsJumpForwardTrigger="<tab>"
              let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
              let g:UltiSnipsEditSplit="vertical"
              nnoremap <silent> <C-s><C-n> :UltiSnipsEdit<CR>
            ]])
		end,
	},
	-- }}}

	-- Fuzzy Finder {{{
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-fzf-native.nvim",
			"nvim-telescope/telescope-frecency.nvim",
			"nvim-telescope/telescope-ghq.nvim",
			"nvim-telescope/telescope-github.nvim",
		},
		config = function()
			-- setup {{{
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					sorting_strategy = "ascending",
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
				},
				pickers = {
					live_grep = {
						additional_args = function(opts)
							return { "--hidden" }
						end,
					},
				},
			})
			-- This is needed to setup telescope-fzf-native. It overrides the sorters
			-- in this.
			telescope.load_extension("fzf")
			telescope.load_extension("frecency")
			telescope.load_extension("ghq")
			telescope.load_extension("gh")
			-- }}}

			-- keymaps for builtin {{{
			local builtin = require("telescope.builtin")
			local get_file_dir = function()
				-- get expand('%:h') if buffer has filename, otherwise use $CWD
				local sibling = vim.fn.expand("%:h")
				if sibling ~= nil and sibling ~= "" then
					return sibling
				end
				return vim.fn.getcwd()
			end

			-- files
			vim.keymap.set("n", "<C-u><C-u>", "<cmd>Telescope find_files hidden=true<cr>", {})
			vim.keymap.set("n", "<M-u><M-u>", function()
				builtin.find_files({ cwd = get_file_dir(), hidden = true })
			end, {})
			-- buffers
			vim.keymap.set("n", "<C-u><C-b>", builtin.buffers, {})
			-- grep
			vim.keymap.set("n", "<C-u><C-g>", builtin.grep_string, {})
			vim.keymap.set("n", "<M-u><M-g>", function()
				builtin.grep_string({ cwd = get_file_dir() })
			end, {})
			vim.keymap.set("n", "<C-u>g", builtin.live_grep, {})
			vim.keymap.set("n", "<M-u>g", function()
				builtin.live_grep({ cwd = get_file_dir() })
			end, {})
			-- buffer lines
			vim.keymap.set("n", "<C-u><C-l>", function()
				builtin.current_buffer_fuzzy_find({ skip_empty_lines = true })
			end, {})
			-- file types
			vim.keymap.set("n", "<C-u><C-t>", builtin.filetypes, {})
			-- lsp diagnostics
			vim.keymap.set("n", "<C-u><C-e>", builtin.diagnostics, {})
			-- lsp
			vim.keymap.set("n", "<C-u>sr", builtin.lsp_references)
			vim.keymap.set("n", "<C-u>sd", builtin.lsp_document_symbols)
			vim.keymap.set("n", "<C-u>sw", ":Telescope lsp_workspace_symbols query=")
			-- resume
			vim.keymap.set("n", "<C-u><C-r>", builtin.resume, {})
			-- command history
			vim.keymap.set("n", "<C-u>ch", builtin.command_history, {})
			vim.keymap.set("n", "<C-u>cr", builtin.commands, {})
			-- git
			vim.keymap.set("n", "<C-u>Gc", builtin.git_commits, {})
			vim.keymap.set("n", "<C-u>Gg", builtin.git_bcommits, {})
			vim.keymap.set("n", "<C-u>Gr", builtin.git_branches, {})
			-- }}}

			-- keymaps for extensions {{{
			local function extensions(t)
				local name, prop, opt = t[1], t[2], t[3] or {}
				return function()
					return telescope.extensions[name][prop](opt)
				end
			end

			-- frecency
			vim.keymap.set("n", "<C-u><C-h>", extensions({ "frecency", "frecency" }))
			-- ghq
			vim.keymap.set(
				"n",
				"<C-u>hq",
				extensions({
					"ghq",
					"list",
					{
						attach_mappings = function(_)
							local actions_set = require("telescope.actions.set")
							actions_set.select:replace(function(_, _)
								local from_entry = require("telescope.from_entry")
								local actions_state = require("telescope.actions.state")
								local entry = actions_state.get_selected_entry()
								local dir = from_entry.path(entry)
								builtin.git_files({ cwd = dir, show_untracked = true })
							end)
							return true
						end,
					},
				})
			)
			-- }}}
		end,
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
		config = function()
			vim.cmd([[
              nnoremap [nerdtree] <Nop>
              nmap <Leader>e [nerdtree]
              nnoremap <silent> [nerdtree]c :NERDTreeFind<CR>
              nnoremap <silent> [nerdtree]n :NERDTreeToggle<CR>
              nnoremap <silent> [nerdtree]r :NERDTree .<CR>

              let g:NERDTreeShowHidden=1
              let g:NERDTreeChDirMode=2
              let g:NERDTreeIgnore = ['\.pyc$', '__pycache__']
            ]])
		end,
	},
	{
		"majutsushi/tagbar",
		config = function()
			vim.cmd([[
                nmap <Leader>c :TagbarToggle<CR>
            ]])
		end,
	},
	-- }}}

	-- git {{{
	{
		"tpope/vim-fugitive",
		config = function()
			vim.cmd([[
              nnoremap [fugitive] <Nop>
              nmap     <Leader>g   [fugitive]
              nnoremap <silent> [fugitive]b :Git blame<CR>
              nnoremap <silent> [fugitive]B :GBrowse<CR>
              nnoremap <silent> [fugitive]s :tab Git<CR>
              nnoremap <silent> [fugitive]w :Gwrite<CR>
              nnoremap <silent> [fugitive]c :Gcommit<CR>
              nnoremap <silent> [fugitive]d :Gdiffsplit<CR>
              nnoremap <silent> [fugitive]r :tab Git! diff <CR>
              nnoremap <silent> [fugitive]R :tab Git! diff --staged<CR>
            ]])
		end,
	},
	{ "tpope/vim-rhubarb", dependencies = {
		"tpope/vim-fugitive",
	} },
	{ "tpope/vim-dispatch" },
	{
		"rbong/vim-flog",
		config = function()
			vim.cmd([[
              nnoremap <silent> <Leader>gv :Flog<CR>
              nnoremap <silent> <Leader>gV :Flogsplit -path=%<CR>
              let g:flog_default_opts = {
                \ 'max_count': 2000,
                \ 'all': 1,
                \ }
              augroup FlogBindings
                au!
                au FileType floggraph nnoremap <buffer> <silent> <Tab> :<C-U>call flog#set_commit_mark_at_line('m', '.') \| call flog#run_command('vertical botright Gsplit %h:%p', 0, 0, 1)<CR>
                au FileType floggraph nnoremap <buffer> <silent> df :<C-U>call flog#run_command("vertical botright Gsplit %(h'm):%p \| Gdiffsplit %h", 0, 0, 1)<CR>
              augroup END
            ]])
		end,
	},
	{
		"sindrets/diffview.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("diffview").setup({
				view = {
					merge_tool = {
						layout = "diff3_mixed",
					},
				},
			})
			vim.keymap.set("n", "<Leader>gM", "<cmd>DiffviewOpen<cr>", { silent = true })
			vim.keymap.set("n", "<Leader>gc", "<cmd>DiffviewClose<cr>", { silent = true })
			vim.keymap.set("n", "<Leader>gH", "<cmd>DiffviewFileHistory<cr>", { silent = true })
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					-- Navigation
					map("n", "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(function()
							gs.next_hunk()
						end)
						return "<Ignore>"
					end, { expr = true })

					map("n", "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true })

					-- Actions
					map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>")
					map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>")
					map("n", "<leader>hS", gs.stage_buffer)
					map("n", "<leader>hu", gs.undo_stage_hunk)
					map("n", "<leader>hR", gs.reset_buffer)
					map("n", "<leader>hp", gs.preview_hunk)
					map("n", "<leader>hb", function()
						gs.blame_line({ full = true })
					end)
					map("n", "<leader>tb", gs.toggle_current_line_blame)
					map("n", "<leader>hd", gs.diffthis)
					map("n", "<leader>hD", function()
						gs.diffthis("~")
					end)
					map("n", "<leader>td", gs.toggle_deleted)

					-- Integrate with trouble.nvim
					map({ "n", "v" }, "<leader>hq", ":Gitsigns setqflist<CR>")

					-- Text object
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
				end,
			})
		end,
	},
	-- }}}

	-- Language & Syntax {{{
	{
		-- go
		"fatih/vim-go",
		ft = "go",
		config = function()
			vim.cmd([[
              augroup GolangGroup
                autocmd!

                let g:go_fmt_command = "goimports"
                let g:go_def_mapping_enabled = 0
                let g:go_doc_keywordprg_enabled = 0
                let g:go_auto_type_info = 1
                let g:go_auto_sameids = 1
                let g:go_highlight_build_constraints = 1
                let g:go_highlight_extra_types = 1
                let g:go_highlight_fields = 1
                let g:go_highlight_functions = 1
                let g:go_highlight_methods = 1
                let g:go_highlight_operators = 1
                let g:go_highlight_structs = 1
                let g:go_highlight_types = 1
                let g:go_list_type = "quickfix"

                function! s:build_go_files()
                  let l:file = expand('%')
                  if l:file =~# '^\f\+_test\.go$'
                    call go#test#Test(0, 1)
                  elseif l:file =~# '^\f\+\.go$'
                    call go#cmd#Build(0)
                  endif
                endfunction

                autocmd FileType go nmap <Leader>i <Plug>(go-info)
                autocmd FileType go nnoremap <Leader>b :<C-u>call <SID>build_go_files()<CR>
                autocmd FileType go nmap <Leader>x <Plug>(go-run)
                autocmd FileType go nmap <Leader>A <Plug>(go-alternate-edit)
                autocmd FileType go nmap <Leader>t <Plug>(go-test)
                autocmd FileType go nmap <Leader>T :GoTestFunc<CR>
                autocmd FileType go nmap <Leader>C <Plug>(go-coverage-toggle)
              augroup END
            ]])
		end,
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
	-- js
	{
		"pangloss/vim-javascript",
		config = function()
			vim.cmd([[
              let g:javascript_plugin_flow = 1
            ]])
		end,
	},
	{ "leafgarland/typescript-vim" },
	{
		"peitalin/vim-jsx-typescript",
		config = function()
			vim.cmd([[
              autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx
            ]])
		end,
	},
	-- markdown
	{
		"plasticboy/vim-markdown",
		dependencies = {
			"godlygeek/tabular",
		},
		config = function()
			vim.cmd([[
              let g:vim_markdown_conceal = 0
              let g:vim_markdown_conceal_code_blocks = 0
              let g:tex_conceal = ""
              let g:vim_markdown_math = 1
              autocmd FileType markdown nmap <Leader>T :TableFormat<CR>
            ]])
		end,
	},
	-- swift
	{ "keith/swift.vim" },
	-- toml
	{ "cespare/vim-toml" },
	-- nginx
	{ "chr4/nginx.vim" },
	-- Dockerfile
	{ "ekalinin/Dockerfile.vim" },
	-- plantuml
	{
		"aklt/plantuml-syntax",
		config = function()
			vim.cmd([[
              augroup PlantUMLGroup
                autocmd!
                au FileType plantuml command! OpenUml :!google-chrome %
              augroup END
            ]])
		end,
	},
	-- tmux
	{ "tmux-plugins/vim-tmux" },
	-- terraform
	{
		"hashivim/vim-terraform",
		config = function()
			vim.cmd([[
              autocmd! BufWritePre *.tf execute ':TerraformFmt'
            ]])
		end,
	},
	-- jsonnet
	{ "google/vim-jsonnet" },
	-- sql
	{
		"nanotee/sqls.nvim",
		config = function()
			vim.cmd([[
              augroup SQLGroup
                autocmd!
                autocmd FileType sql nmap <Leader>E :SqlsExecuteQuery<CR>
                autocmd FileType sql nmap <Leader>C :SqlsShowConnections<CR>
                autocmd FileType sql nmap <Leader>S :SqlsSwitchConnection 
              augroup END
            ]])
		end,
	},
	-- }}}

	-- LSP {{{
	{
		"williamboman/mason.nvim",
		config = function()
			local mason = require("mason")
			mason.setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
			"folke/neodev.nvim",
			"nanotee/sqls.nvim",
		},
		config = function()
			local nvim_lsp = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			require("neodev").setup({})
			mason_lspconfig.setup({
				ensure_installed = {
					"bashls",
					"gopls",
					"jsonls",
					"jsonnet_ls",
					"pyright",
					"rust_analyzer",
					"solargraph",
					"sumneko_lua",
					"sqls",
					"terraformls",
					"tflint",
				},
			})
			mason_lspconfig.setup_handlers({
				function(server_name)
					local opts = {
						on_attach = require("plugins.lsp.handler").on_attach,
						capabilities = require("plugins.lsp.handler").capabilities,
					}
					if server_name == "solargraph" then
						local solargraph_opts = { single_file_support = true }
						opts = vim.tbl_deep_extend("force", opts, solargraph_opts)
					end
					if server_name == "bashls" then
						local bashls_opts = require("plugins.lsp.settings.bashls")
						opts = vim.tbl_deep_extend("force", opts, bashls_opts)
					end
					if server_name == "pyright" then
						local pyright_opts = require("plugins.lsp.settings.pyright")
						opts = vim.tbl_deep_extend("force", opts, pyright_opts)
					end
					if server_name == "sumneko_lua" then
						local sumneko_opts = require("plugins.lsp.settings.sumneko_lua")
						opts = vim.tbl_deep_extend("force", opts, sumneko_opts)
					end
					if server_name == "sqls" then
						opts.on_attach = function(client, bufnr)
							require("plugins.lsp.handler").on_attach(client, bufnr)
							require("sqls").on_attach(client, bufnr)
						end
					end
					nvim_lsp[server_name].setup(opts)
				end,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local nvim_lsp = require("lspconfig")
			local opts = {
				on_attach = require("plugins.lsp.handler").on_attach,
				capabilities = require("plugins.lsp.handler").capabilities,
			}
			nvim_lsp.sourcekit.setup(vim.tbl_deep_extend("force", opts, {
				single_file_support = true,
			}))

			vim.keymap.set("n", "<C-g>il", ":LspInfo<CR>", { silent = true })
		end,
	},
	{
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				debug = true,
				sources = {
					null_ls.builtins.diagnostics.shellcheck,
					null_ls.builtins.diagnostics.mypy,
					null_ls.builtins.diagnostics.flake8,
					null_ls.builtins.diagnostics.rubocop,
					null_ls.builtins.diagnostics.sqlfluff,
					null_ls.builtins.diagnostics.tfsec,
					null_ls.builtins.formatting.black,
					null_ls.builtins.formatting.jq,
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.gofmt,
					null_ls.builtins.formatting.gofumpt,
					null_ls.builtins.formatting.goimports,
					null_ls.builtins.formatting.golines,
					null_ls.builtins.formatting.rubocop,
					null_ls.builtins.formatting.rustfmt,
					null_ls.builtins.formatting.shfmt.with({
						extra_args = { "-i", "2", "-sr" },
					}),
					null_ls.builtins.formatting.sqlfluff,
				},
				on_attach = require("plugins.lsp.handler").on_attach,
			})

			vim.keymap.set("n", "<C-g>in", ":NullLsInfo<CR>", { silent = true })
		end,
	},
	-- {
	-- "prabirshrestha/vim-lsp",
	-- config = function()
	-- vim.cmd([[
	-- " swift
	-- if executable('sourcekit-lsp')
	-- au User lsp_setup call lsp#register_server({
	-- \ 'name': 'sourcekit-lsp',
	-- \ 'cmd': {server_info->['sourcekit-lsp']},
	-- \ 'allowlist': ['swift'],
	-- \ })
	-- endif

	-- " python
	-- if (executable('pylsp'))
	-- augroup LspPython
	-- autocmd!
	-- autocmd User lsp_setup call lsp#register_server({
	-- \ 'name': 'pylsp',
	-- \ 'cmd': {server_info->['pylsp']},
	-- \ 'allowlist': ['python']
	-- \ })
	-- augroup END
	-- endif

	-- " Terraform
	-- if executable('terraform-ls')
	-- au User lsp_setup call lsp#register_server({
	-- \ 'name': 'terraform-ls',
	-- \ 'cmd': {server_info->['terraform-ls', 'serve']},
	-- \ 'allowlist': ['terraform'],
	-- \ })
	-- endif

	-- function! s:on_lsp_buffer_enabled() abort
	-- setlocal omnifunc=lsp#complete
	-- setlocal signcolumn=yes
	-- if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
	-- nmap <buffer> <C-g><C-d> <plug>(lsp-definition)
	-- nmap <buffer> <C-g><C-s> <plug>(lsp-document-symbol-search)
	-- nmap <buffer> <C-g><C-w> <plug>(lsp-workspace-symbol-search)
	-- nmap <buffer> <C-g><C-r> <plug>(lsp-references)
	-- nmap <buffer> <C-g><C-i> <plug>(lsp-implementation)
	-- nmap <buffer> <C-g><C-t> <plug>(lsp-type-definition)
	-- nmap <buffer> <C-g><C-f> <plug>(lsp-document-format)
	-- nmap <buffer> <C-g>r <plug>(lsp-rename)
	-- nmap <buffer> [g <plug>(lsp-previous-diagnostic)
	-- nmap <buffer> ]g <plug>(lsp-next-diagnostic)
	-- nmap <buffer> <C-g>d :LspDocumentDiagnostics<CR>
	-- nmap <buffer> K <plug>(lsp-hover)

	-- let g:lsp_format_sync_timeout = 1000
	-- autocmd! BufWritePre *.rs,*.go,*.py call execute('LspDocumentFormatSync')
	-- autocmd! BufWritePre *.rb,*.rake call execute('LspDocumentFormatSync --server=solargraph')
	-- endfunction

	-- augroup lsp_install
	-- au!
	-- " call s:on_lsp_buffer_enabled only for languages that has the server registered.
	-- autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
	-- augroup END

	-- " Debugging
	-- " let g:lsp_log_verbose = 1
	-- " let g:lsp_log_file = expand('~/vim-lsp.log')
	-- ]])
	-- end,
	-- },
	-- {
	-- "mattn/vim-lsp-settings",
	-- config = function()
	-- vim.cmd([[
	-- let g:lsp_diagnostics_echo_cursor = 1

	-- " Enable flake8 and mypy
	-- let g:lsp_settings = {
	-- \  'pylsp-all': {
	-- \    'workspace_config': {
	-- \      'pylsp': {
	-- \        'configurationSources': ['flake8'],
	-- \        'plugins': {
	-- \          'flake8': {
	-- \            'enabled': 1
	-- \          },
	-- \          'mccabe': {
	-- \            'enabled': 0
	-- \          },
	-- \          'pycodestyle': {
	-- \            'enabled': 0
	-- \          },
	-- \          'pyflakes': {
	-- \            'enabled': 0
	-- \          },
	-- \          'pylsp_mypy': {
	-- \            'enabled': 1
	-- \          }
	-- \        }
	-- \      }
	-- \    }
	-- \  }
	-- \}
	-- ]])
	-- end,
	-- },
	-- }}}

	-- Diagnostics {{{
	{
		"folke/trouble.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("trouble").setup({
				height = 20,
			})
			vim.keymap.set("n", "<leader>dd", "<cmd>TroubleToggle<cr>", { silent = true, noremap = true })
			vim.keymap.set(
				"n",
				"<leader>dw",
				"<cmd>TroubleToggle workspace_diagnostics<cr>",
				{ silent = true, noremap = true }
			)
			vim.keymap.set(
				"n",
				"<leader>db",
				"<cmd>TroubleToggle document_diagnostics<cr>",
				{ silent = true, noremap = true }
			)
			vim.keymap.set("n", "<leader>dl", "<cmd>TroubleToggle loclist<cr>", { silent = true, noremap = true })
			vim.keymap.set("n", "<leader>dq", "<cmd>TroubleToggle quickfix<cr>", { silent = true, noremap = true })
			vim.keymap.set(
				"n",
				"<leader>dr",
				"<cmd>TroubleToggle lsp_references<cr>",
				{ silent = true, noremap = true }
			)
		end,
	},
	-- }}}

	-- Runner {{{
	{
		"Shougo/vimproc.vim",
		build = "make",
	},
	{
		"thinca/vim-quickrun",
		dependencies = {
			"Shougo/vimproc.vim",
		},
		config = function()
			vim.cmd([[
              nmap <silent> <Leader>ru :QuickRun<CR>
              let g:quickrun_config = {}
              "let g:quickrun_config._ = {
              "\   'runner' : 'vimproc',
              "\   'runner/vimproc/updatetime' : 40,
              "\}
              let g:quickrun_config.python = {
              \ 'command': expand('~/.pyenv/shims/python'),
              \}
              let g:quickrun_config.swift = {
              \ 'command': 'xcrun',
              \ 'cmdopt': 'swift',
              \ 'exec': '%c %o %s',
              \}
              let g:quickrun_config.haskell = {
              \ 'command': 'stack',
              \ 'cmdopt': 'runghc',
              \}
            ]])
		end,
	},
	-- }}}

	-- Testing {{{
	{
		"janko/vim-test",
		config = function()
			vim.cmd([[
              nmap <silent> t<C-n> :TestNearest<CR>
              nmap <silent> t<C-f> :TestFile<CR>
              autocmd FileType go nmap <silent> t<C-n> :TestNearest -v -count=1<CR>
              autocmd FileType go nmap <silent> t<C-f> :TestFile -v -count=1<CR>
            ]])
		end,
	},
	-- }}}
})
