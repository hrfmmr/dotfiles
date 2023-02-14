return function()
	vim.cmd([[
  augroup GolangGroup
    autocmd!

    let g:go_fmt_command = "goimports"
    let g:go_def_mapping_enabled = 0
    let g:go_doc_keywordprg_enabled = 0
    let g:go_auto_type_info = 1
    let g:go_auto_sameids = 1
    let g:go_highlight_build_constraints = 1
    let g:go_highlight_extra_types = 1
    let g:go_highlight_fields = 1
    let g:go_highlight_functions = 1
    let g:go_highlight_methods = 1
    let g:go_highlight_operators = 1
    let g:go_highlight_structs = 1
    let g:go_highlight_types = 1
    let g:go_list_type = "quickfix"

    function! s:build_go_files()
      let l:file = expand('%')
      if l:file =~# '^\f\+_test\.go$'
        call go#test#Test(0, 1)
      elseif l:file =~# '^\f\+\.go$'
        call go#cmd#Build(0)
      endif
    endfunction

    autocmd FileType go nmap <Leader>i <Plug>(go-info)
    autocmd FileType go nnoremap <Leader>b :<C-u>call <SID>build_go_files()<CR>
    autocmd FileType go nmap <Leader>x <Plug>(go-run)
    autocmd FileType go nmap <Leader>A <Plug>(go-alternate-edit)
    autocmd FileType go nmap <Leader>t <Plug>(go-test)
    autocmd FileType go nmap <Leader>T :GoTestFunc<CR>
    autocmd FileType go nmap <Leader>C <Plug>(go-coverage-toggle)
  augroup END
    ]])
end
