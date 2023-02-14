return function()
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
			["<C-k>"] = cmp.mapping.complete(),
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
end
