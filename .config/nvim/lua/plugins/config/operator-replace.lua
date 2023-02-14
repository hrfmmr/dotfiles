return {
	dependencies = {
		"kana/vim-operator-user",
	},
	config = function()
		vim.cmd("map R <Plug>(operator-replace)")
	end,
}
