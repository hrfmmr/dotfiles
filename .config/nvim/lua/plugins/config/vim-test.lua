return function()
	vim.cmd([[
  nmap <silent> t<C-n> :TestNearest<CR>
  nmap <silent> t<C-f> :TestFile<CR>
  autocmd FileType go nmap <silent> t<C-n> :TestNearest -v -count=1<CR>
  autocmd FileType go nmap <silent> t<C-f> :TestFile -v -count=1<CR>
  ]])
end
