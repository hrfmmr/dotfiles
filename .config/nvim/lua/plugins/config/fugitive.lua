return function()
	vim.cmd([[
  nnoremap [fugitive] <Nop>
  nmap     <Leader>g   [fugitive]
  nnoremap <silent> [fugitive]b :Git blame<CR>
  nnoremap <silent> [fugitive]B :GBrowse<CR>
  nnoremap <silent> [fugitive]s :tab Git<CR>
  nnoremap <silent> [fugitive]w :Gwrite<CR>
  nnoremap <silent> [fugitive]c :Gcommit<CR>
  nnoremap <silent> [fugitive]d :Gdiffsplit<CR>
  nnoremap <silent> [fugitive]r :tab Git! diff <CR>
  nnoremap <silent> [fugitive]R :tab Git! diff --staged<CR>
  ]])
end
