return function()
	vim.cmd([[
  nnoremap <silent> <Leader>gv :Flog<CR>
  nnoremap <silent> <Leader>gV :Flogsplit -path=%<CR>
  let g:flog_default_opts = {
    \ 'max_count': 2000,
    \ 'all': 1,
    \ }
  augroup FlogBindings
    au!
    au FileType floggraph nnoremap <buffer> <silent> <Tab> :<C-U>call flog#set_commit_mark_at_line('m', '.') \| call flog#run_command('vertical botright Gsplit %h:%p', 0, 0, 1)<CR>
    au FileType floggraph nnoremap <buffer> <silent> df :<C-U>call flog#run_command("vertical botright Gsplit %(h'm):%p \| Gdiffsplit %h", 0, 0, 1)<CR>
  augroup END
  ]])
end
