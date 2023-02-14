return {
	init = function()
		vim.cmd("let g:NERDCreateDefaultMappings = 0")
	end,
	config = function()
		vim.cmd([[
  let g:NERDSpaceDelims = 1
  nmap <Space>/ <Plug>NERDCommenterToggle
  vmap <Space>s <Plug>NERDCommenterSexy
  ]])
	end,
}
