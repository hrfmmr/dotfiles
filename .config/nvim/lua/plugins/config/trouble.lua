return {
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("trouble").setup({
			height = 10,
		})
		vim.keymap.set("n", "<leader>dd", "<cmd>Trouble toggle<cr>", { silent = true, noremap = true })
		vim.keymap.set("n", "<leader>dw", "<cmd>Trouble diagnostics toggle<cr>", { silent = true, noremap = true })
		vim.keymap.set(
			"n",
			"<leader>db",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			{ silent = true, noremap = true }
		)
		vim.keymap.set("n", "<leader>ds", "<cmd>Trouble symbols toggle<cr>", { silent = true, noremap = true })
		vim.keymap.set("n", "<leader>dr", "<cmd>Trouble lsp_references toggle<cr>", { silent = true, noremap = true })

		vim.keymap.set("n", "<leader>dl", "<cmd>Trouble loclist toggle<cr>", { silent = true, noremap = true })
		vim.keymap.set("n", "<leader>dq", "<cmd>Trouble quickfix toggle<cr>", { silent = true, noremap = true })
	end,
}
