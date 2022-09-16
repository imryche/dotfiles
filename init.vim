call plug#begin()

Plug 'arcticicestudio/nord-vim'
Plug 'itchyny/lightline.vim'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() }}
Plug 'junegunn/fzf.vim'

Plug 'ervandew/supertab'

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'dense-analysis/ale'
Plug 'ludovicchabant/vim-gutentags'

Plug 'tpope/vim-unimpaired'
Plug 'airblade/vim-gitgutter'

Plug 'preservim/nerdcommenter'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'

Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'

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
nnoremap <leader>q :q<cr>
nnoremap <leader>c :nohl<cr>

nnoremap <leader>d :Explore<cr>
nnoremap <leader>D :Lexplore<cr>

nnoremap <leader>/ :Rg<cr>
nnoremap <leader>; :Buffers<cr>
nnoremap <leader>l :BLines<cr>
nnoremap <leader>p :Files<cr>

nnoremap gj :ALENextWrap<cr>
nnoremap gk :ALEPreviousWrap<cr>
nnoremap g1 :ALEFirst<cr>

map <leader>' <plug>NERDCommenterToggle

let g:SuperTabDefaultCompletionType = "<c-n>"
let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all,ctrl-d:deselect-all'

lua <<EOF
require('nvim-treesitter.configs').setup {
  ensure_installed = { "c", "lua", "python" },
  sync_install = false,
  auto_install = true,
  ignore_install = { "javascript" },

  highlight = {
    enable = true,
    disable = {},
    additional_vim_regex_highlighting = false,
  },
}
EOF
