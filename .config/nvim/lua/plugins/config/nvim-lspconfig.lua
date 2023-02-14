return function()
	local nvim_lsp = require("lspconfig")
	local opts = {
		on_attach = require("plugins.lsp.handler").on_attach,
		capabilities = require("plugins.lsp.handler").capabilities,
	}
	nvim_lsp.sourcekit.setup(vim.tbl_deep_extend("force", opts, {
		single_file_support = true,
	}))

	vim.keymap.set("n", "<C-g>il", ":LspInfo<CR>", { silent = true })
end
