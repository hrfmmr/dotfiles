return function()
	require("nvim-treesitter.configs").setup({
		highlight = {
			enable = true,
		},
		ensure_installed = "all",
	})
end
