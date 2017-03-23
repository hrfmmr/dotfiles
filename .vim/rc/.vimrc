"---------------------------------------------------------------------------
" Initialize:
"
if &compatible
  set nocompatible
endif

set rtp+=$VIMRUNTIME

function! s:source_rc(path, ...) abort "{{{
  let use_global = get(a:000, 0, !has('vim_starting'))
  let abspath = resolve(expand('~/.vim/rc/' . a:path))
  if !use_global
    execute 'source' fnameescape(abspath)
    return
  endif

  " substitute all 'set' to 'setglobal'
  let content = map(readfile(abspath),
        \ 'substitute(v:val, "^\\W*\\zsset\\ze\\W", "setglobal", "")')
  " create tempfile and source the tempfile
  let tempfile = tempname()
  try
    call writefile(content, tempfile)
    execute printf('source %s', fnameescape(tempfile))
  finally
    if filereadable(tempfile)
      call delete(tempfile)
    endif
  endtry
endfunction"}}}

" Set augroup.
augroup MyAutoCmd
  autocmd!
augroup END


"---------------------------------------------------------------------------
" Encoding:
"
call s:source_rc('encoding.rc.vim')


"---------------------------------------------------------------------------
" Mappings:
"
call s:source_rc('mappings.rc.vim')


"---------------------------------------------------------------------------
" Basic:
"
set relativenumber number
set imdisable
if !has('nvim')
    set antialias
endif


"---------------------------------------------------------------------------
" Edit:
"
inoremap ( ()<ESC>i
inoremap <expr> ) ClosePair(')')
inoremap { {}<ESC>i
inoremap <expr> } ClosePair('}')
inoremap [ []<ESC>i
inoremap <expr> ] ClosePair(']')
inoremap < <><ESC>i
" pair close checker.
" from othree vimrc ( http://github.com/othree/rc/blob/master/osx/.vimrc )
function! ClosePair(char)
    if getline('.')[col('.') - 1] == a:char
        return "\<Right>"
    else
        return a:char
    endif
endf

if has('nvim')
    if has('unix')
        if has('mac')
            set clipboard=unnamed
        else
            set clipboard=unnamedplus
        endif
    endif
else
    set clipboard+=unnamed
    if has('unnamedplus')
        set clipboard& clipboard+=unnamedplus
    else
        set clipboard& clipboard+=unnamed,autoselect
    endif
endif


"---------------------------------------------------------------------------
" GUI:
"
set t_Co=256
set visualbell t_vb=
set cmdheight=4
set showmatch
set wildmode=list,full
set guioptions-=T
set showtabline=2
if has('unix')
    if !has('mac')
        highlight Normal ctermbg=none
    endif
endif
if has('nvim')
    if has('termguicolors')
        set termguicolors
    endif
    let g:terminal_color_0 = "\#232c33"
	let g:terminal_color_1 = "\#99736e"
	let g:terminal_color_2 = "\#78a090"
	let g:terminal_color_3 = "\#bfb7a1"
	let g:terminal_color_4 = "\#7c9fa6"
	let g:terminal_color_5 = "\#BF9C86"
	let g:terminal_color_6 = "\#99BFBA"
	let g:terminal_color_7 = "\#f0f0f0"
	let g:terminal_color_8 = "\#70838c"
	let g:terminal_color_9 = "\#99736e"
	let g:terminal_color_10 = "\#78a090"
	let g:terminal_color_11 = "\#bfb7a1"
	let g:terminal_color_12 = "\#7c9fa6"
	let g:terminal_color_13 = "\#BF9C86"
	let g:terminal_color_14 = "\#99BFBA"
	let g:terminal_color_15 = "\#f0f0f0"
endif

"---------------------------------------------------------------------------
" Backup:
"
set nobackup
set noswapfile
set noundofile


"---------------------------------------------------------------------------
" File:
"
set hidden
set autoread


"---------------------------------------------------------------------------
" Search:
"
set ignorecase
set smartcase
set wrapscan
set incsearch
set hlsearch
cnoremap <expr> / getcmdtype() == '/' ? '\/' : '/'
cnoremap <expr> ? getcmdtype() == '?' ? '\?' : '?'


"---------------------------------------------------------------------------
" Indent:
"
set expandtab
set smarttab
set autoindent
set smartindent
set backspace=indent,eol,start
set whichwrap=b,s,h,l,<,>,[,]
set ts=4 sts=4 sw=4
augroup IndentGroup
    autocmd!
    au BufNewFile,BufRead *.py setlocal ts=4 sts=4 sw=4
    au BufNewFile,BufRead *.{sh} setlocal ts=2 sts=2 sw=2
    au BufNewFile,BufRead *.{json,xml,html,toml,yaml,yml} setlocal ts=2 sts=2 sw=2
    au BufNewFile,BufRead *.{css,scss} setlocal ts=2 sts=2 sw=2
    au BufNewFile,BufRead *.{js,coffee,cjsx,jsx,es6,ts} setlocal ts=2 sts=2 sw=2
    au BufNewFile,BufRead *.{rb,podspec},Vagrantfile,Podfile,Appfile,Fastfile,Matchfile,Gymfile,Snapfile,Scanfile setlocal ts=2 sts=2 sw=2
augroup END

"---------------------------------------------------------------------------
" Completion:
"
augroup completion
  autocmd!
  autocmd CompleteDone * pclose!
augroup END

"---------------------------------------------------------------------------
" Ctags:
"
" Ctags for each languages
nnoremap <C-d> :<C-u>tab stj <C-R>=expand('<cword>')<CR><CR>
augroup CtagsGroup
    autocmd!
    au BufNewFile,BufRead *.py set tags=~/py.tags
    au BufNewFile,BufRead *.rb set tags=~/rb.tags
augroup END


"---------------------------------------------------------------------------
" Invisible word settings:
"
set list
set listchars=tab:>\ ,eol:~
augroup highlightZenkakuSpace
		autocmd!
		autocmd VimEnter,ColorScheme * highlight ZenkakuSpace term=underline ctermbg=Red guibg=Red
		autocmd VimEnter,WinEnter * match ZenkakuSpace /　/
augroup ENDase


"---------------------------------------------------------------------------
" Functions:
"
call s:source_rc('functions.rc.vim')


"---------------------------------------------------------------------------
" Plugins:
"
if filereadable(expand("~/.vim/rc/plugins.vim"))
    source ~/.vim/rc/plugins.vim
endif

syntax on
filetype plugin indent on
