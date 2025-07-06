return function()
	vim.cmd([[
  let g:previm_open_cmd = 'open -a "Arc"'
  nmap <Leader>P :PrevimOpen<CR>
  ]])
end
