return function()
	vim.cmd([[
  augroup SQLGroup
    autocmd!
    autocmd FileType sql nmap <Leader>E :SqlsExecuteQuery<CR>
    autocmd FileType sql nmap <Leader>C :SqlsShowConnections<CR>
    autocmd FileType sql nmap <Leader>S :SqlsSwitchConnection 
  augroup END
  ]])
end
