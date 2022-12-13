call plug#begin()

Plug 'cocopon/iceberg.vim'
Plug 'nvim-lualine/lualine.nvim'

Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'dense-analysis/ale'

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

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
set clipboard+=unnamedplus

filetype plugin indent on

syntax on
set termguicolors
colorscheme iceberg

set completeopt=menu,menuone,noselect

let mapleader=" "

nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

nnoremap <C-d> <C-d>zz
nnoremap <C-d> <C-d>zz
nnoremap n nzzzv
nnoremap N Nzzzv

nnoremap <leader>1 :only<cr>
nnoremap <leader>3 :vsp<cr>
nnoremap <leader>2 :sp<cr>
nnoremap <leader>d :bd<cr>

nnoremap <leader>s :w<cr>
nnoremap <leader>o <c-^>
nnoremap <leader>q :q<cr>
nnoremap <leader>c :nohl<cr>

nnoremap <leader>e :Ex<cr>

let g:ale_set_signs = 0
let g:ale_fixers = {'c': ['clang-format'], 'python': ['isort', 'black'], 'json': ['jq']}
let g:ale_linters = {'python': ['flake8']}
nnoremap gj :ALENextWrap<cr>
nnoremap gk :ALEPreviousWrap<cr>
nnoremap g1 :ALEFirst<cr>
nnoremap <leader>= :ALEFix<cr>

autocmd TermOpen * setlocal nonumber norelativenumber

lua <<EOF
-- Set up lualine
require('lualine').setup {
  options = { section_separators = '', component_separators = '', theme = 'iceberg' }
}

-- Set up nvim-treesitter
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

-- Set up telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fs', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fw', function() builtin.grep_string({ search = vim.fn.expand("<cword>") }) end, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Set up nvim-cmp
local cmp = require'cmp'

cmp.setup({
  snippet = { },
  window = { },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
  }, {
    { name = 'buffer' },
  })
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Set up lspconfig.
local opts = { noremap=true, silent=true }

local on_attach = function(client, bufnr)
  -- Mappings.
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', '<space>.', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
end

lspconfig = require "lspconfig"
util = require "lspconfig/util"

lspconfig.pyright.setup{
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities=capabilities,
}

lspconfig.gopls.setup {
  on_attach = on_attach,
  cmd = {"gopls", "serve"},
  filetypes = {"go", "gomod"},
  root_dir = util.root_pattern("go.work", "go.mod", ".git"),
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
    },
  },
}

vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
EOF
