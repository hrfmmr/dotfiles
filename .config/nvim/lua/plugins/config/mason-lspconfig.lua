return {
	dependencies = {
		"williamboman/mason.nvim",
		"neovim/nvim-lspconfig",
		"folke/neodev.nvim",
	},
	config = function()
		local mason_lspconfig = require("mason-lspconfig")
		local handler = require("plugins.lsp.handler")

		require("neodev").setup({})

		vim.lsp.config("*", {
			on_attach = handler.on_attach,
			capabilities = handler.capabilities,
		})

		vim.lsp.config("clangd", require("plugins.lsp.settings.clangd"))
		vim.lsp.config("solargraph", { single_file_support = true })
		vim.lsp.config("bashls", require("plugins.lsp.settings.bashls"))
		vim.lsp.config("pyright", require("plugins.lsp.settings.pyright"))
		vim.lsp.config("ts_ls", require("plugins.lsp.settings.ts_ls"))
		vim.lsp.config("denols", require("plugins.lsp.settings.denols"))
		vim.lsp.config("lua_ls", require("plugins.lsp.settings.lua_ls"))

		mason_lspconfig.setup({
			ensure_installed = {
				"bashls",
				"clangd",
				"gopls",
				"jsonls",
				"jsonnet_ls",
				"pyright",
				"rust_analyzer",
				"solargraph",
				"lua_ls",
				"sqlls",
				"terraformls",
				"tflint",
				"buf_ls",
				"ts_ls",
				"denols",
			},
			automatic_enable = true,
		})
	end,
}
