return {
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("diffview").setup({
			view = {
				merge_tool = {
					layout = "diff3_mixed",
				},
			},
		})
		vim.keymap.set("n", "<Leader>gM", "<cmd>DiffviewOpen<cr>", { silent = true })
		vim.keymap.set("n", "<Leader>gc", "<cmd>DiffviewClose<cr>", { silent = true })
		vim.keymap.set("n", "<Leader>gH", "<cmd>DiffviewFileHistory %<cr>", { silent = true })
	end,
}
