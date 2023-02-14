return {
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("trouble").setup({
			height = 20,
		})
		vim.keymap.set("n", "<leader>dd", "<cmd>TroubleToggle<cr>", { silent = true, noremap = true })
		vim.keymap.set(
			"n",
			"<leader>dw",
			"<cmd>TroubleToggle workspace_diagnostics<cr>",
			{ silent = true, noremap = true }
		)
		vim.keymap.set(
			"n",
			"<leader>db",
			"<cmd>TroubleToggle document_diagnostics<cr>",
			{ silent = true, noremap = true }
		)
		vim.keymap.set("n", "<leader>dl", "<cmd>TroubleToggle loclist<cr>", { silent = true, noremap = true })
		vim.keymap.set("n", "<leader>dq", "<cmd>TroubleToggle quickfix<cr>", { silent = true, noremap = true })
		vim.keymap.set("n", "<leader>dr", "<cmd>TroubleToggle lsp_references<cr>", { silent = true, noremap = true })
	end,
}
