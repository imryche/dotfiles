call plug#begin('~/.vim/plugged')

Plug 'mileszs/ack.vim'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-surround'
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'othree/html5.vim'
Plug 'othree/xml.vim'
Plug 'airblade/vim-gitgutter'
Plug 'majutsushi/tagbar'
Plug 'fisadev/vim-isort'
Plug 'davidhalter/jedi-vim'
Plug 'Vimjas/vim-python-pep8-indent'
Plug 'ervandew/supertab'
Plug 'w0rp/ale'
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
Plug 'ntpeters/vim-better-whitespace'
Plug 'pangloss/vim-javascript'
Plug 'nanotech/jellybeans.vim'
Plug 'nathanaelkane/vim-indent-guides'

call plug#end()

" Add the virtualenv's site-packages to vim path
if has('python')
py << EOF
import os.path
import sys
import vim
if 'VIRTUAL_ENV' in os.environ:
    project_base_dir = os.environ['VIRTUAL_ENV']
    sys.path.insert(0, project_base_dir)
    activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
    execfile(activate_this, dict(__file__=activate_this))
EOF
endif

filetype plugin indent on

syntax on
set termguicolors
colorscheme jellybeans
let python_highlight_all = 1

" Map leader key to ,
let mapleader = ","

set nocompatible
set encoding=utf-8
set background=dark

" Wrapping
set nowrap
" set textwidth=0

" Reduce <ESC> timeout
set ttimeout
set ttimeoutlen=20
set notimeout

set number
set numberwidth=4
set ruler
set showcmd

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

" Always show tab bar at the top
set showtabline=2

" Disable folding
set nofoldenable

" Indentation settings
au BufNewFile,BufRead *.py
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4 |
    \ set textwidth=79 |
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix

au BufNewFile,BufRead *.js,*.html,*.css:
    \ set tabstop=2 |
    \ set softtabstop=2 |
    \ set shiftwidth=2 |
    \ set autoindent |
    \ set expandtab

au BufNewFile,BufRead *.c,*.h:
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4

au BufNewFile,BufRead *.json
    \ set ts=4 |
    \ set sts=4 |
    \ set sw=4 |
    \ set expandtab |
    \ set autoindent

au BufRead,BufNewFile *.yml set filetype=ansible

autocmd Filetype html setlocal ts=2 sts=2 sw=2
autocmd Filetype css setlocal ts=2 sts=2 sw=2

" ========= KEY MAPPINGS =========

nnoremap <leader><leader> <C-^>
noremap <leader>q :q<CR>
noremap <leader>c :bd<CR>
noremap <leader>s :write<CR>
" noremap <leader>f :Ack ""<Left>
" noremap <leader>F :Ack "<C-r>""<Space>

" Move vertically by visual line
nnoremap j gj
nnoremap k gk

" Easy buffer navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

nnoremap <leader>vs :vs<CR>
nnoremap <leader>hs :sp<CR>

" Map folding to the spacebar
nnoremap <space> za

" Edit vimrc/zshrc and load vimrc bindings
nnoremap <leader>ev :vsp ~/.vimrc<CR>
nnoremap <leader>ez :vsp ~/.zshrc<CR>
nnoremap <leader>erc :source ~/.vimrc<CR>

" CtrlP mappings
let g:ctrlp_map = '<leader>f'
let g:ctrlp_cmd = 'CtrlP'

" Open BufExplorer
nnoremap <leader>b :BufExplorer<CR>

" Open NERDTree buffer
map <C-n> :NERDTreeToggle<CR>
map <C-i> :NERDTreeFind<CR>

" Open Tagbar buffer
nmap <C-t> :TagbarToggle<CR>

nnoremap <leader>ib oimport ipdb; ipdb.set_trace()<ESC>
nnoremap <leader>ic ofrom celery.contrib import rdb; rdb.set_trace()<ESC>

" Write compile and run C program
autocmd FileType c nnoremap <leader>l :w <CR> :!gcc % -o %< && ./%< <CR>
autocmd FileType python noremap <leader>l :w <CR> :!python % <CR>
autocmd FileType javascript noremap <leader>l :w <CR> :!node % <CR>

" ========= PLUGINS CONFIGURATION =========

" NERDTree options
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let NERDTreeIgnore=['\.pyc$', '\~$', '__pycache__']
let g:NERDTreeWinSize=40

" Ale
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_linters = {'python': ['flake8'],}
let g:ale_python_flake8_options = '--max-line-length=120'
let g:ale_python_pylint_options = '--ignore=C0301'
let g:ale_set_highlights = 0

" Supertab
let g:SuperTabDefaultCompletionType = "context"

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

" Airline
let g:airline_theme='deus'
let g:airline#extensions#ale#enabled = 1
