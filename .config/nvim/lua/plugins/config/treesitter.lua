	return function()
		-- nvim-treesitter `main` branch (the `master` branch is frozen and breaks on Neovim 0.12:
		-- its query directives expect a single TSNode per capture, but 0.12 passes a list).
		local languages = {
			"bash",
			"c",
			"cpp",
			"go",
			"gomod",
			"json",
			"jsonnet",
			"lua",
			"markdown",
			"markdown_inline",
			"python",
			"ruby",
			"rust",
			"sql",
			"swift",
			"terraform",
			"hcl",
			"toml",
			"tsx",
			"typescript",
			"vim",
			"yaml",
		}

		-- `jsonc` has no dedicated parser on `main`; reuse the json one
		vim.treesitter.language.register("json", "jsonc")

		require("nvim-treesitter").setup({})
		-- async; skips parsers that are already installed (requires the tree-sitter CLI)
		require("nvim-treesitter").install(languages)

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				-- no-op for filetypes without a parser
				pcall(vim.treesitter.start, args.buf)
			end,
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "json",
			callback = function()
				vim.opt_local.foldmethod = "expr"
				vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.opt_local.foldlevel = 2
			end,
		})
	end
