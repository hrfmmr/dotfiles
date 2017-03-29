call NERDTreeAddKeyMap({
      \ 'key': 'yy',
      \ 'callback': 'NERDTreeYankCurrentNode',
      \ 'quickhelpText': 'put full path of current node into the default register'
      \ })

function! NERDTreeYankCurrentNode()
  let n = g:NERDTreeFileNode.GetSelected()
  if n != {}
    if has('mac')
        call system("pbcopy", n.path.str())
    else
        call system("xsel -bi", n.path.str())
    endif
    echo "yanked: " . n.path.str()
  endif
endfunction
