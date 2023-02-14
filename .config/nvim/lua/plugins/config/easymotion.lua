return function()
	vim.cmd([[
  let g:EasyMotion_do_mapping = 0
  let g:EasyMotion_keys = ';a,oqepughtcrnwv'
  let g:EasyMotion_smartcase = 1
  nmap s <Plug>(easymotion-s2)
  xmap s <Plug>(easymotion-s2)
  nmap <Leader>s <Plug>(easymotion-sn)
  xmap <Leader>s <Plug>(easymotion-sn)
  map <Leader>j <Plug>(easymotion-j)
  map <Leader>k <Plug>(easymotion-k)
  let g:EasyMotion_enter_jump_first = 1
  let g:EasyMotion_space_jump_first = 1
  let g:EasyMotion_startofline = 0
  ]])
end
