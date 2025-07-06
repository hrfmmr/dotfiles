return function()
	local nvim_lsp = require("lspconfig")
	local opts = {
		on_attach = require("plugins.lsp.handler").on_attach,
		capabilities = require("plugins.lsp.handler").capabilities,
	}
	-- sourcekit
	nvim_lsp.sourcekit.setup(vim.tbl_deep_extend("force", opts, require("plugins.lsp.settings.sourcekit")))

	vim.keymap.set("n", "<C-g>il", ":LspInfo<CR>", { silent = true })
end
