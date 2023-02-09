vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4

vim.cmd([[
if !exists('g:tagbar_type_markdown')
    let g:tagbar_type_markdown = {
      \ 'ctagstype': 'markdown',
      \ 'ctagsbin' : '~/src/github.com/jszakmeister/markdown2ctags/markdown2ctags.py',
      \ 'ctagsargs' : '-f - --sort=yes --sro=»',
      \ 'kinds' : [
          \ 's:sections',
          \ 'i:images'
      \ ],
      \ 'sro' : '»',
      \ 'kind2scope' : {
          \ 's' : 'section',
      \ },
      \ 'sort': 0,
    \ }
endif
]])
