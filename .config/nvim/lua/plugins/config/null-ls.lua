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

	local ruff_diagnostics = require_extra('none-ls.diagnostics.ruff')
	if ruff_diagnostics and vim.fn.executable('ruff') == 1 then
		table.insert(diagnostics, ruff_diagnostics)
	else
		if ruff_diagnostics then
			vim.notify('ruff executable not found; skipping diagnostics.ruff', vim.log.levels.INFO)
		end
	end

	local formatting = {
		null_ls.builtins.formatting.clang_format.with({
			filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
		}),
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

	local ruff_format = require_extra('none-ls.formatting.ruff_format')
	if ruff_format and vim.fn.executable('ruff') == 1 then
		table.insert(formatting, ruff_format)
	else
		if ruff_format then
			vim.notify('ruff executable not found; skipping formatting.ruff_format', vim.log.levels.INFO)
		end
	end

	local jq = require_extra('none-ls.formatting.jq')
	if vim.fn.executable('jq') == 1 then
		if jq then
			table.insert(formatting, jq)
		elseif null_ls.builtins.formatting.jq then
			table.insert(formatting, null_ls.builtins.formatting.jq)
		end
	else
		vim.notify('jq executable not found; skipping jq formatter', vim.log.levels.INFO)
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
