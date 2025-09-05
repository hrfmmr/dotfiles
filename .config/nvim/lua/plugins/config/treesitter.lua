return function()
	require("nvim-treesitter.configs").setup({
		highlight = {
			enable = true,
		},
		ensure_installed = "all",
	})

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "json",
		callback = function()
			vim.opt_local.foldmethod = "expr"
			vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
			vim.opt_local.foldlevel = 2
		end,
	})
end
