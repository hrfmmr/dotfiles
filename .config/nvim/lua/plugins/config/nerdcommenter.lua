return {
	init = function()
		vim.cmd("let g:NERDCreateDefaultMappings = 0")
	end,
	config = function()
		vim.cmd([[
    let g:NERDSpaceDelims = 1
    let g:NERDCustomDelimiters = {
    \ 'swift': { 'left': '//' }
    \ }
    nmap <Space>/ <Plug>NERDCommenterToggle
    vmap <Space>/ <Plug>NERDCommenterToggle
    vmap <Space>s <Plug>NERDCommenterSexy
    ]])
	end,
}
