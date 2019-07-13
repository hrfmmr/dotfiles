" dein settings {{{

let g:dein#types#git#clone_depth = 1

autocmd MyAutoCmd VimEnter * call dein#call_hook('post_source')

let $CACHE = expand('~/.cache')

if !isdirectory(expand($CACHE))
  call mkdir(expand($CACHE), 'p')
endif

" dein root
let s:dein_dir = expand('$CACHE/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'
" if dein doesn't exists, clone it
if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
endif
execute 'set runtimepath^=' . s:dein_repo_dir

if dein#load_state(s:dein_dir)
    call dein#begin(s:dein_dir)

    let s:toml = '~/.vim/rc/dein.toml'
    call dein#load_toml(s:toml, {'lazy': 0})

    call dein#end()
    call dein#save_state()
endif

if has('vim_starting') && dein#check_install()
  call dein#install()
endif

if !has('vim_starting')
  call dein#recache_runtimepath()
  call dein#call_hook('add')
  call dein#call_hook('source')
  call dein#call_hook('post_source')
endif
" }}}
