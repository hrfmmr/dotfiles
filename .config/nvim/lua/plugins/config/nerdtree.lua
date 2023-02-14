return function()
	vim.cmd([[
  nnoremap [nerdtree] <Nop>
  nmap <Leader>e [nerdtree]
  nnoremap <silent> [nerdtree]c :NERDTreeFind<CR>
  nnoremap <silent> [nerdtree]n :NERDTreeToggle<CR>
  nnoremap <silent> [nerdtree]r :NERDTree .<CR>

  let g:NERDTreeShowHidden=1
  let g:NERDTreeChDirMode=2
  let g:NERDTreeIgnore = ['\.pyc$', '__pycache__']
  ]])
end
