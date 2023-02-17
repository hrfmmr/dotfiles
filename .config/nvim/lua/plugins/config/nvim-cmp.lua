return {
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-nvim-lua",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/cmp-emoji",
		"andersevenrud/cmp-tmux",
		"lukas-reineke/cmp-rg",
		"quangnguyen30192/cmp-nvim-ultisnips",
		-- "octaltree/cmp-look",
	},
	config = function()
		local cmp = require("cmp")
		local cmp_ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")
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
				["<C-k>"] = cmp.mapping.complete({}),
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
				["<Tab>"] = cmp.mapping(function(fallback)
					cmp_ultisnips_mappings.expand_or_jump_forwards(fallback)
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					cmp_ultisnips_mappings.jump_backwards(fallback)
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
				{ name = "ultisnips" },
				-- { name = "look", keyword_length = 2, option = { convert_case = true, loud = true } },
			}),
		})

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
}
