call plug#begin('~/.vim/plugged')

Plug 'mileszs/ack.vim'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-surround'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'othree/html5.vim'
Plug 'othree/xml.vim'
Plug 'airblade/vim-gitgutter'
Plug 'python-mode/python-mode'
Plug 'davidhalter/jedi-vim'
Plug 'tmhedberg/SimpylFold'
Plug 'scrooloose/syntastic'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'jlanzarotta/bufexplorer'
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'kien/ctrlp.vim'
Plug 'mattn/emmet-vim'
Plug 'altercation/vim-colors-solarized'
Plug 'glench/vim-jinja2-syntax'
Plug 'pearofducks/ansible-vim'
Plug 'janko-m/vim-test'
Plug 'vim-scripts/c.vim'

call plug#end()

filetype plugin indent on

syntax on
colorscheme solarized

" Map leader key to ,
let mapleader = ","

set nocompatible
set encoding=utf-8
set background=dark

" Reduce <ESC> timeout
set ttimeout
set ttimeoutlen=20
set notimeout

set number
set ruler
set showcmd

set re=1 " Old regex engine that actually works faster
set lazyredraw
set wildmenu

" Edit another buffer without saving previous
set hidden

set autoread
set autowrite " Automatically write before running commands

" Search
set nohlsearch
set incsearch
set ignorecase
set smartcase

" Keep more content at the bottom of the buffer
set scrolloff=3

" Configure backspace so it acts as it should act
set backspace=eol,start,indent

" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile

" Split settings
set splitbelow
set splitright
set diffopt+=vertical

" Enable folding
set foldmethod=indent
set foldlevel=99

" Indentation settings
au BufNewFile,BufRead *.py:
    \ set tabstop=4
    \ set softtabstop=4
    \ set shiftwidth=4
    \ set textwidth=79
    \ set expandtab
    \ set autoindent
    \ set fileformat=unix

au BufNewFile,BufRead *.js, *.html, *.css:
    \ set tabstop=2
    \ set softtabstop=2
    \ set shiftwidth=2

au BufNewFile,BufRead *.c,*.h:
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4

au BufRead,BufNewFile *.yml set filetype=ansible

autocmd Filetype html setlocal ts=2 sts=2 sw=2
autocmd Filetype jinja setlocal ts=2 sts=2 sw=2
autocmd Filetype css setlocal ts=2 sts=2 sw=2

" ========= KEY MAPPINGS ========= 

noremap <leader>c :bd<CR>
noremap <leader>s :write<CR>
noremap <leader>f :Ack ""<Left>
noremap <leader>F :Ack "<C-r>""<Space>

" Move vertically by visual line
nnoremap j gj
nnoremap k gk

" Easy buffer navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Map folding to the spacebar
nnoremap <space> za

" Edit vimrc/zshrc and load vimrc bindings
nnoremap <leader>ev :vsp $MYVIMRC<CR>
nnoremap <leader>ez :vsp ~/.zshrc<CR>
nnoremap <leader>erc :source $MYVIMRC<CR>

" Open BufExplorer
nnoremap <leader>b :BufExplorer<CR>

" Open NERDTree buffer
map <C-n> :NERDTreeToggle<CR>

" Write compile and run C program
nnoremap <leader>b :w <CR> :!gcc % -o %< && ./%< <CR>

" ========= PLUGINS CONFIGURATION ========= 

" NERDTree options
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let NERDTreeIgnore=['\.pyc$', '\~$']
let g:NERDTreeWinSize=40

" Syntastic
let g:syntastic_python_checkers=['flake8']
let g:syntastic_python_flake8_args='--ignore=E501,E225'
let g:syntastic_python_pylint_post_args="--max-line-length=120"

" Pymode
let g:pymode_options_max_line_length = 120
let g:pymode_breakpoint_bind = '<leader>br'
let g:pymode_virtualenv = 1
let g:pymode_rope = 0

" Jedi
let g:jedi#smart_auto_mappings = 0
let g:jedi#popup_on_dot = 0

" UltiSnips
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" CtrlP
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

" BufExplorer
let g:bufExplorerDisableDefaultKeyMapping=1
let g:bufExplorerShowRelativePath=1

" SimpylFold
let g:SimpylFold_docstring_preview=1

" Airline
let g:airline_theme='solarized'
