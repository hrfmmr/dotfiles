return function()
	vim.cmd([[
  nnoremap [ghprblame] <Nop>
  nmap     <Leader>gl   [ghprblame]
  nnoremap <silent> [ghprblame]l :GHPRBlame<CR>
  nnoremap <silent> [ghprblame]L :GHPRBlameQuit<CR>
  ]])
end
