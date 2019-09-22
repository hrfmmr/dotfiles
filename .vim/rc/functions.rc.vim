" http://vim.wikia.com/wiki/List_loaded_scripts
"
" Execute 'cmd' while redirecting output.
" Delete all lines that do not match regex 'filter' (if not empty).
" Delete any blank lines.
" Delete '<whitespace><number>:<whitespace>' from start of each line.
" Display result in a scratch buffer.
function! s:Filter_lines(cmd, filter)
  let save_more = &more
  set nomore
  redir => lines
  silent execute a:cmd
  redir END
  let &more = save_more
  new
  setlocal buftype=nofile bufhidden=hide noswapfile
  put =lines
  g/^\s*$/d
  %s/^\s*\d\+:\s*//e
  if !empty(a:filter)
    execute 'v/' . a:filter . '/d'
  endif
  0
endfunction
command! -nargs=? Scriptnames call s:Filter_lines('scriptnames', <q-args>)

" Add preferable PATH to $PATH
function! UnshiftPath(p)
  let $PATH=a:p.':'.$PATH
endfunction
command! -nargs=* UnshiftPath call UnshiftPath(<f-args>)

function! ImInActivate()
  call system('fcitx-remote -c')
endfunction
if has('unix')
  if !has('mac')
    inoremap <silent> <C-[> <ESC>:call ImInActivate()<CR><ESC>
  endif
endif

function! s:Jq(...)
  if 0 == a:0
    let l:arg = "."
  else
    let l:arg = a:1
  endif
  execute "%! jq \"" . l:arg . "\""
endfunction
command! -nargs=? Jq call s:Jq(<f-args>)

function! OpenModifiableLL()
  lopen
  set modifiable
  set nowrap
endfunction

function! OpenModifiableQF()
  cw
  set modifiable
  set nowrap
endfunction

function! s:VimGrep(q, ...)
  let file_pattern = get(a:, 1, '%')
  execute 'vimgrep /\v' . a:q . '/ ' . file_pattern
endfunction
command! -nargs=+ V call s:VimGrep(<f-args>)
