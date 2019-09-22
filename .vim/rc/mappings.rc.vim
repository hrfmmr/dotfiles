" Map Leader Key
let g:mapleader=","

map s <Nop>

" Insert new line
nmap <CR> i<CR><ESC>

" Close pair
" https://vim.fandom.com/wiki/Making_Parenthesis_And_Brackets_Handling_Easier
inoremap ( ()<Esc>i
inoremap [ []<Esc>i
inoremap { {<CR>}<Esc>O
autocmd Syntax html,vim inoremap < <lt>><Esc>i| inoremap > <c-r>=ClosePair('>')<CR>
inoremap ) <c-r>=ClosePair(')')<CR>
inoremap ] <c-r>=ClosePair(']')<CR>
inoremap } <c-r>=CloseBracket()<CR>
inoremap " <c-r>=QuoteDelim('"')<CR>
inoremap ' <c-r>=QuoteDelim("'")<CR>

function ClosePair(char)
 if getline('.')[col('.') - 1] == a:char
 return "\<Right>"
 else
 return a:char
 endif
endf

function CloseBracket()
 if match(getline(line('.') + 1), '\s*}') < 0
 return "\<CR>}"
 else
 return "\<Esc>j0f}a"
 endif
endf

function QuoteDelim(char)
 let line = getline('.')
 let col = col('.')
 if line[col - 2] == "\\"
 "Inserting a quoted quotation mark into the string
 return a:char
 elseif line[col - 1] == a:char
 "Escaping out of the string
 return "\<Right>"
 else
 "Starting a string
 return a:char.a:char."\<Esc>i"
 endif
endf
" Selection
nnoremap vv vf
nnoremap vV vF
" Switch tab
nnoremap gc gt
nnoremap gr gT
" Move tab
nnoremap <silent> gC :+tabm<CR>
nnoremap <silent> gR :-tabm<CR>
" Emacs key bind for moving cursole while INSERT
inoremap <c-n> <down>
inoremap <c-p> <up>
inoremap <c-b> <left>
inoremap <c-f> <right>
inoremap <c-a> <Esc>_i
inoremap <c-e> <Esc>$a
" Split window
nnoremap <silent> <Space>V :new<CR>
nnoremap <silent> <Space>H :vne<CR>
" Switch window
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-l> <c-w>l
nnoremap <c-h> <c-w>h
" paging
noremap <Space>j <c-f>
noremap <Space>k <c-b>
" File write/quit/update
noremap <silent> <Space>w :w<CR>
noremap <silent> <Space>q :q<CR>
noremap <silent> <Space>Q :bd!<CR>
noremap <silent> <Space>e :e!<CR>
" Tab Handling
nnoremap <silent> <leader>te :<C-u>tabedit<CR>
nnoremap <silent> <leader>tc :<C-u>tabclose<CR>
nnoremap <silent> <leader>tf :tabfirst<CR>
nnoremap <silent> <leader>tl :tablast<CR>
nnoremap <silent> <leader>ts :tab<space>split<CR>
" Search visual selected
vnoremap // y/<C-R>"<CR>
" Location List
nnoremap <silent> <leader>lo :call OpenModifiableLL()<CR>
nnoremap <silent> <leader>lc :lclose<CR>
" Jump definition
nnoremap <C-d> :<C-u>tab stj <C-R>=expand('<cword>')<CR><CR>
" quickfix
nnoremap <silent> [q :cprevious<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [Q :<C-u>cfirst<CR>
nnoremap <silent> ]Q :<C-u>clast<CR>
nnoremap <silent> <leader>qo :call OpenModifiableQF()<CR>
nnoremap <silent> <leader>qc :cclose<CR>

" Terminal Emulator
if has("nvim")
  noremap <silent> <C-t> :term<CR>
  tnoremap <C-[> <C-\><C-n>
endif
