return function()
	require("catppuccin").setup({
		flavour = "mocha",
		background = {
			light = "latte",
			dark = "mocha",
		},
		transparent_background = true,
		term_colors = true,
	})
	vim.cmd([[colorscheme catppuccin]])
	vim.cmd("highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE")
end
