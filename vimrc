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

" Map leader key to ,
let mapleader = ","

" Reduce <ESC> timeout
set ttimeout
set ttimeoutlen=20
set notimeout

" Custom key mappings
map <leader>f :Ack ""<Left>
map <leader>F :Ack "<C-r>""<Space>
map <leader>c :bd<CR>
map <leader>s :w<CR>
map <leader>sa :wa<CR>
imap <expr> <tab> emmet#expandAbbrIntelligent("\<tab>")
imap <C-Return> <CR><CR><C-o>k<Tab>

" Write compile and run C program
nnoremap <leader>b :w <CR> :!gcc % -o %< && ./%< <CR>

" move vertically by visual line
nnoremap j gj
nnoremap k gk

" edit vimrc/zshrc and load vimrc bindings
nnoremap <leader>ev :vsp $MYVIMRC<CR>
nnoremap <leader>ez :vsp ~/.zshrc<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" NERDTree options
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let NERDTreeIgnore=['\.pyc$', '\~$']
let g:NERDTreeWinSize=40
map <C-n> :NERDTreeToggle<CR>
nmap <C-i> :NERDTreeFind<CR>

" Pymode options
let g:syntastic_python_checkers=['flake8']
let g:syntastic_python_flake8_args='--ignore=E501,E225'
let g:syntastic_python_pylint_post_args="--max-line-length=120"
let g:pymode_options_max_line_length = 120
let g:pymode_breakpoint_bind = '<leader>br'
let g:pymode_virtualenv = 1
let g:pymode_rope = 0

" Jedi options
let g:jedi#smart_auto_mappings = 0
let g:jedi#popup_on_dot = 0

" UltiSnips configuration
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

set nocompatible
set encoding=utf-8
set number
set lazyredraw
set ruler
set wildmenu
set showcmd
set hidden
set autoread
set relativenumber
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

" Split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Enable folding
set foldmethod=indent
set foldlevel=99

" Map folding to the spacebar
nnoremap <space> za

" SimpylFold options
let g:SimpylFold_docstring_preview=1

" Nice indentation
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

syntax on
set background=dark
colorscheme solarized
let g:airline_theme='solarized'
