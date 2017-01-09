" Map Leader Key
let g:mapleader=","

map s <Nop>

" Dvorak F
nnoremap t f
nnoremap T F

" Selection
nnoremap vv vf
nnoremap vV vF
" Switch tab
nnoremap gc gt
nnoremap gr gT
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
noremap <silent> <Space>e :e!<CR>
" Tab Handling
nnoremap <silent> <leader>te :<C-u>tabedit<CR>
nnoremap <silent> <leader>tc :<C-u>tabclose<CR>
nnoremap <C-[> :tabprevious<CR>
nnoremap <C-]> :tabnext<CR>
nnoremap <silent> <leader>tf :tabfirst<CR>
nnoremap <silent> <leader>tl :tablast<CR>
nnoremap <silent> <leader>ts :tab<space>split<CR>
" Search visual selected
vnoremap // y/<C-R>"<CR>
" Search prefixing
cnoremap <expr> / getcmdtype() == '/' ? '\/' : '/'
cnoremap <expr> ? getcmdtype() == '?' ? '\?' : '?'
" Location List
nnoremap <silent> <leader>lo :lopen<CR>
nnoremap <silent> <leader>lc :lclose<CR>

" Terminal Emulator
if has("nvim")
    noremap <silent> <C-t> :term<CR>
    tnoremap <C-[> <C-\><C-n>
endif
