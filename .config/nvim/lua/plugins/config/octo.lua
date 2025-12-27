return {
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("octo").setup()
		vim.cmd([[
    hi! link OctoEditable Search
    augroup OctoGroup
    autocmd!
      autocmd FileType octo       nmap <silent> <Leader>co :Octo pr checkout<CR>
      autocmd FileType octo       nmap <silent> <Leader>rs :Octo review start<CR>
      autocmd FileType octo       nmap <silent> <Leader>rr :Octo review resume<CR>
      autocmd FileType octo       nmap <silent> <Leader>rc :Octo review comments<CR>
      autocmd FileType octo_panel nmap <silent> <Leader>sb :Octo review submit<CR>
    augroup END
	nmap <silent><Leader>rl :Octo pr list<CR>
	nmap <Leader>re :Octo pr edit<Space>
    ]])
	end,
}
