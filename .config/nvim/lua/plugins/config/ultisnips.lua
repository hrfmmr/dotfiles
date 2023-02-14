return {
	dependencies = {
		"honza/vim-snippets",
	},
	config = function()
		vim.cmd([[
    let g:UltiSnipsJumpForwardTrigger="<tab>"
    let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
    let g:UltiSnipsEditSplit="vertical"
    nnoremap <silent> <C-s><C-n> :UltiSnipsEdit<CR>
    ]])
	end,
}
