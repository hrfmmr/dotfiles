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
execute 'set rtp^=' . s:dein_repo_dir

if dein#load_state(s:dein_dir)
    call dein#begin(s:dein_dir)

    call dein#load_toml('~/.vim/rc/dein/dein.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/colors.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/completions.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/editing.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/explorer.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/formatter.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/git.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/lang.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/lsp.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/runner.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/snippets.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/syntax.toml', {'lazy': 0})
    call dein#load_toml('~/.vim/rc/dein/testing.toml', {'lazy': 0})

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
