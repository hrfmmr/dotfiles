return function()
	local ok, null_ls = pcall(require, "none-ls")
	if not ok then
		ok, null_ls = pcall(require, "null-ls")
	end
	if not ok then
		vim.notify("none-ls.nvim(null-ls) が読み込めません。:Lazy sync などでプラグインを取得してください。", vim.log.levels.WARN)
		return
	end

	local function require_extra(mod)
		local ok_extra, builtin = pcall(require, mod)
		if not ok_extra then
			vim.notify(('none-ls "%s" の読み込みに失敗しました: %s'):format(mod, builtin), vim.log.levels.WARN)
			return nil
		end
		return builtin
	end

	local diagnostics = {
		null_ls.builtins.diagnostics.buf,
		null_ls.builtins.diagnostics.cppcheck,
		null_ls.builtins.diagnostics.mypy,
		null_ls.builtins.diagnostics.rubocop,
		null_ls.builtins.diagnostics.sqlfluff,
		null_ls.builtins.diagnostics.tfsec,
	}

	local shellcheck = require_extra('none-ls.diagnostics.shellcheck')
	if shellcheck then
		table.insert(diagnostics, shellcheck)
	elseif null_ls.builtins.diagnostics.shellcheck then
		table.insert(diagnostics, null_ls.builtins.diagnostics.shellcheck)
	else
		vim.notify('shellcheck source not available; install shellcheck or none-ls-shellcheck.nvim', vim.log.levels.INFO)
	end

	local flake8 = require_extra('none-ls.diagnostics.flake8')
	if flake8 then
		flake8 = flake8.with({ extra_args = { '--max-line-length', '88' } })
		table.insert(diagnostics, flake8)
	end

	local formatting = {
		null_ls.builtins.formatting.clang_format.with({
			filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
		}),
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.isort,
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.gofmt,
		null_ls.builtins.formatting.gofumpt,
		null_ls.builtins.formatting.goimports,
		null_ls.builtins.formatting.golines,
		null_ls.builtins.formatting.prettier.with({
			filetypes = { 'typescript', 'typescriptreact' },
		}),
		null_ls.builtins.formatting.shfmt.with({
			extra_args = { '-i', '2', '-sr' },
		}),
		null_ls.builtins.formatting.sql_formatter,
		null_ls.builtins.formatting.buf,
	}

	local jq = require_extra('none-ls.formatting.jq')
	if jq then
		table.insert(formatting, jq)
	else
		table.insert(formatting, null_ls.builtins.formatting.jq)
	end

	local sources = {}
	vim.list_extend(sources, diagnostics)
	vim.list_extend(sources, formatting)

	null_ls.setup({
		debug = true,
		sources = sources,
		on_attach = require('plugins.lsp.handler').on_attach,
	})

	vim.keymap.set('n', '<C-g>in', ':NullLsInfo<CR>', { silent = true })
end
