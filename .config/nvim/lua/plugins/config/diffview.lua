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
		vim.keymap.set("n", "<Leader>gc", function()
			local rev = vim.fn.input("Base rev (commit/branch/tag): ")
			if rev ~= "" then
				-- Pass through as-is if it already specifies a range (`..` / `...` / `^!`)
				if rev:find("%.%.") or rev:find("%^!") then
					vim.cmd("DiffviewOpen " .. rev)
				else
					vim.cmd("DiffviewOpen " .. rev .. "...HEAD")
				end
			end
		end, { silent = true })
		vim.keymap.set("n", "<Leader>gC", "<cmd>DiffviewClose<cr>", { silent = true })
		vim.keymap.set("n", "<Leader>gH", "<cmd>DiffviewFileHistory %<cr>", { silent = true })
	end,
}
