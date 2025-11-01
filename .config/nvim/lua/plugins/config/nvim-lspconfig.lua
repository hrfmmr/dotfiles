return function()
	vim.lsp.config("sourcekit", require("plugins.lsp.settings.sourcekit"))
	vim.lsp.enable("sourcekit")

	vim.keymap.set("n", "<C-g>il", ":LspInfo<CR>", { silent = true })
end
