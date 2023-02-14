return function()
	vim.cmd([[
  let g:windowswap_map_keys = 0 
  nnoremap <silent> <leader>ww :call WindowSwap#EasyWindowSwap()<CR>
  ]])
end
