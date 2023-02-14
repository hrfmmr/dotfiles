return function()
	vim.cmd([[
  let g:previm_open_cmd = 'open -a "Google Chrome"'
  nmap <Leader>P :PrevimOpen<CR>
  ]])
end
