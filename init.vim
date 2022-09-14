call plug#begin()

Plug 'arcticicestudio/nord-vim'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() }}
Plug 'junegunn/fzf.vim'
Plug 'dense-analysis/ale'
Plug 'ervandew/supertab'
Plug 'vim-scripts/AutoComplPop'
Plug 'preservim/nerdcommenter'
Plug 'airblade/vim-gitgutter'
Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'

call plug#end()

set relativenumber
set nocompatible
set cursorline
set scrolloff=3
set wildmenu
set nobackup
set nowritebackup

syntax on
set termguicolors
colorscheme nord
let g:nord_bold=0
let g:lightline = { 'colorscheme': 'nord' }

set completeopt=menu,preview

let mapleader=" "

nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

nnoremap <leader>v :vsp<cr>
nnoremap <leader>h :sp<cr>

nnoremap <leader>s :w<cr>
nnoremap <leader><tab> <c-^>
nnoremap <leader>o :only<cr>
nnoremap <leader>k :q<cr>

nnoremap <leader>d :Explore<cr>
nnoremap <leader>D :Lexplore<cr>

nnoremap <leader>/ :Rg<cr>
nnoremap <leader>; :Buffers<cr>
nnoremap <leader>l :BLines<cr>
nnoremap <leader>p :Files<cr>

nnoremap gj :ALENextWrap<cr>
nnoremap gk :ALEPreviousWrap<cr>
nnoremap g1 :ALEFirst<cr>

let g:SuperTabDefaultCompletionType = "<c-n>"

map <leader>' <plug>NERDCommenterToggle
