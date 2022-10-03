call plug#begin()

Plug 'arcticicestudio/nord-vim'
Plug 'nvim-lualine/lualine.nvim'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() }}
Plug 'junegunn/fzf.vim'

Plug 'francoiscabrol/ranger.vim'
Plug 'rbgrouleff/bclose.vim'

Plug 'ervandew/supertab'

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'dense-analysis/ale'
Plug 'neovim/nvim-lspconfig'
" Plug 'ludovicchabant/vim-gutentags'

Plug 'tpope/vim-unimpaired'

Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'

Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'

call plug#end()

set history=10000
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set laststatus=2
set showmatch
set ignorecase smartcase
set number
set relativenumber
set nocompatible
set cursorline
set cmdheight=1
set hidden
set switchbuf=useopen
set scrolloff=3
set wildmenu
set nobackup
set nowritebackup
set noswapfile
set backspace=indent,eol,start

filetype plugin indent on

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

nnoremap <leader>1 :only<cr>
nnoremap <leader>3 :vsp<cr>
nnoremap <leader>2 :sp<cr>
nnoremap <leader>d :bd<cr>

nnoremap <leader>s :w<cr>
nnoremap <leader>o <c-^>
nnoremap <leader>q :q<cr>
nnoremap <leader>c :nohl<cr>

nnoremap <leader>/ :Rg<cr>
nnoremap <leader>; :Buffers<cr>
nnoremap <leader>l :BLines<cr>
nnoremap <leader>p :Files<cr>

nnoremap <leader>r :Ranger<cr>

let g:ale_set_signs = 0
let g:ale_fixers = {'python': ['isort', 'black']}
let g:ale_linters = {'python': ['flake8']}
nnoremap gj :ALENextWrap<cr>
nnoremap gk :ALEPreviousWrap<cr>
nnoremap g1 :ALEFirst<cr>
nnoremap <leader>= :ALEFix<cr>

map <leader>' <plug>NERDCommenterToggle

let g:SuperTabDefaultCompletionType = "<c-n>"

let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all,ctrl-d:deselect-all'
" let g:fzf_layout = { 'down': '20' }
let g:fzf_colors =                                                                         
    \ { 'fg':      ['fg', 'Normal'],                                                           
      \ 'bg':      ['bg', 'Normal'],                                                           
      \ 'hl':      ['fg', 'Comment'],                                                          
      \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],                             
      \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],                                       
      \ 'hl+':     ['fg', 'Statement'],                                                        
      \ 'info':    ['fg', 'PreProc'],                                                          
      \ 'border':  ['fg', 'Ignore'],                                                           
      \ 'prompt':  ['fg', 'Conditional'],                                                      
      \ 'pointer': ['fg', 'Exception'],                                                        
      \ 'marker':  ['fg', 'Keyword'],                                                          
      \ 'spinner': ['fg', 'Label'],                                                            
      \ 'header':  ['fg', 'Comment'] } 

autocmd TermOpen * setlocal nonumber norelativenumber

lua <<EOF
require('lualine').setup({
  options = {
    icons_enabled = false
	}
})

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

local opts = { noremap=true, silent=true }

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', '<space>.', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
end

require('lspconfig')['pyright'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
}

vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
EOF
