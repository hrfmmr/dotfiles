return {
	dependencies = {
		"williamboman/mason.nvim",
		"neovim/nvim-lspconfig",
		"folke/neodev.nvim",
		"nanotee/sqls.nvim",
	},
	config = function()
		local nvim_lsp = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")
		require("neodev").setup({})
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
				"sqls",
				"terraformls",
				"tflint",
			},
		})
		mason_lspconfig.setup_handlers({
			function(server_name)
				local opts = {
					on_attach = require("plugins.lsp.handler").on_attach,
					capabilities = require("plugins.lsp.handler").capabilities,
				}
				if server_name == "solargraph" then
					local solargraph_opts = { single_file_support = true }
					opts = vim.tbl_deep_extend("force", opts, solargraph_opts)
				end
				if server_name == "bashls" then
					local bashls_opts = require("plugins.lsp.settings.bashls")
					opts = vim.tbl_deep_extend("force", opts, bashls_opts)
				end
				if server_name == "pyright" then
					local pyright_opts = require("plugins.lsp.settings.pyright")
					opts = vim.tbl_deep_extend("force", opts, pyright_opts)
				end
				if server_name == "lua_ls" then
					local lua_ls_opts = require("plugins.lsp.settings.lua_ls")
					opts = vim.tbl_deep_extend("force", opts, lua_ls_opts)
				end
				if server_name == "sqls" then
					opts.on_attach = function(client, bufnr)
						require("plugins.lsp.handler").on_attach(client, bufnr)
						require("sqls").on_attach(client, bufnr)
					end
				end
				nvim_lsp[server_name].setup(opts)
			end,
		})
	end,
}
