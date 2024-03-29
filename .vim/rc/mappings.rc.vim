" Map Leader Key
let g:mapleader=","

imap <c-c> <ESC>

map s <Nop>

" Insert new line
nmap <CR> i<CR><ESC>


"Selection
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

augroup DebuggingInsertGroup
  autocmd!
  au FileType ruby inoremap <C-v> require "pry";binding.pry
  au FileType python inoremap <C-v> import os; import inspect; from IPython import embed; print(f"🐍 \033[95mat {os.path.basename(__file__)}:{inspect.stack()[1][3]}#{inspect.stack()[0][3]}\033[0m"); embed()
augroup END

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
  tnoremap <C-q> <ESC>
endif
