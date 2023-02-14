return {
	dependencies = {
		"godlygeek/tabular",
	},
	config = function()
		vim.cmd([[
    let g:vim_markdown_conceal = 0
    let g:vim_markdown_conceal_code_blocks = 0
    let g:tex_conceal = ""
    let g:vim_markdown_math = 1
    autocmd FileType markdown nmap <Leader>T :TableFormat<CR>
    ]])
	end,
}
