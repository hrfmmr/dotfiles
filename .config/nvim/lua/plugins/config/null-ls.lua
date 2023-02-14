return function()
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
end
