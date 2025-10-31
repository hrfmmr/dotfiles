return function()
	local ok, none_ls = pcall(require, "none-ls")
	if not ok then
		vim.notify("none-ls.nvim が読み込めません。:Lazy sync などでプラグインを取得してください。", vim.log.levels.WARN)
		return
	end

	none_ls.setup({
		debug = true,
		sources = {
			none_ls.builtins.diagnostics.buf,
			none_ls.builtins.diagnostics.cppcheck,
			none_ls.builtins.diagnostics.shellcheck,
			none_ls.builtins.diagnostics.mypy,
			none_ls.builtins.diagnostics.flake8.with({
				extra_args = { "--max-line-length", "88" },
			}),
			none_ls.builtins.diagnostics.rubocop,
			none_ls.builtins.diagnostics.sqlfluff,
			none_ls.builtins.diagnostics.tfsec,
			none_ls.builtins.formatting.clang_format.with({
				filetypes = { "c", "cpp", "objc", "objcpp" },
			}),
			none_ls.builtins.formatting.black,
			none_ls.builtins.formatting.isort,
			none_ls.builtins.formatting.jq,
			none_ls.builtins.formatting.stylua,
			none_ls.builtins.formatting.gofmt,
			none_ls.builtins.formatting.gofumpt,
			none_ls.builtins.formatting.goimports,
			none_ls.builtins.formatting.golines,
			none_ls.builtins.formatting.prettier.with({
				filetypes = { "typescript", "typescriptreact" },
			}),
			none_ls.builtins.formatting.rustfmt,
			none_ls.builtins.formatting.shfmt.with({
				extra_args = { "-i", "2", "-sr" },
			}),
			none_ls.builtins.formatting.sql_formatter,
			none_ls.builtins.formatting.buf,
		},
		on_attach = require("plugins.lsp.handler").on_attach,
	})

	vim.keymap.set("n", "<C-g>in", ":NoneLsInfo<CR>", { silent = true })
end
