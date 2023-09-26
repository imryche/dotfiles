-- [[ Packer ]]

local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'
local is_bootstrap = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  is_bootstrap = true
  vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
  vim.cmd [[packadd packer.nvim]]
end

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use {
    'neovim/nvim-lspconfig',
    requires = {
      'jose-elias-alvarez/null-ls.nvim',
    },
  }

  use {
    'kristijanhusak/vim-dadbod-ui',
    requires = {
      'tpope/vim-dadbod',
      'kristijanhusak/vim-dadbod-completion',
    },
  }

  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/nvim-cmp',
      'L3MON4D3/LuaSnip',
      'rafamadriz/friendly-snippets',
      'saadparwaiz1/cmp_luasnip',
    },
  }

  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()
      pcall(require('nvim-treesitter.install').update { with_sync = true })
    end,
  }
  use 'nvim-treesitter/nvim-treesitter-context'

  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
    after = 'nvim-treesitter',
  }

  use 'tpope/vim-fugitive'
  use 'akinsho/git-conflict.nvim'

  use 'stevearc/oil.nvim'

  use 'cocopon/iceberg.vim'
  use 'nvim-lualine/lualine.nvim'
  use 'numToStr/Comment.nvim'
  use 'sheerun/vim-polyglot'
  use 'ethanholz/nvim-lastplace'
  use 'famiu/bufdelete.nvim'

  use { 'nvim-telescope/telescope.nvim', branch = '0.1.x', requires = { 'nvim-lua/plenary.nvim' } }
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', cond = vim.fn.executable 'make' == 1 }

  use 'ThePrimeagen/harpoon'
  use 'tpope/vim-unimpaired'
  use 'tpope/vim-surround'

  -- Add custom plugins to packer from ~/.config/nvim/lua/custom/plugins.lua
  local has_plugins, plugins = pcall(require, 'custom.plugins')
  if has_plugins then
    plugins(use)
  end

  if is_bootstrap then
    require('packer').sync()
  end
end)

if is_bootstrap then
  print '=================================='
  print '    Plugins are being installed'
  print '    Wait until Packer completes,'
  print '       then restart nvim'
  print '=================================='
  return
end

-- [[ Options ]]

-- Set highlight on search
vim.o.hlsearch = false

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

-- Basic indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Decrease update time
vim.opt.updatetime = 50
vim.opt.signcolumn = 'no'
vim.opt.scrolloff = 8

-- Set colorscheme
vim.opt.termguicolors = true
vim.cmd [[colorscheme iceberg]]

-- Set completeopt to have a better completion experience
vim.opt.completeopt = 'menuone,noselect'

-- System clipboard (requires xclip system package)
vim.opt.clipboard = 'unnamedplus'

-- Netrw options
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- [[ Key mappings ]]

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Keymaps for better default experience
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Switch windows faster
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Recenter after disorienting jumps
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Emacs like window splits
vim.keymap.set('n', '<leader>2', ':sp<cr>')
vim.keymap.set('n', '<leader>3', ':vsp<cr>')
vim.keymap.set('n', '<leader>1', ':only<cr>')

-- Open netrw
vim.keymap.set('n', '<leader>e', ':Oil<cr>')

-- Buffer actions
vim.keymap.set('n', '<leader>d', ':bd<cr>')
vim.keymap.set('n', '<leader>q', ':q<cr>')
vim.keymap.set('n', '<leader>w', ':w<cr>')
vim.keymap.set('n', '<leader><Tab>', '<C-^>')

-- Dadbod
vim.keymap.set('n', '<leader>c', ':DBUIToggle<cr>')

-- [[ Highlight on yank ]]

local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- [[ Lualine.nvim ]]

require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'iceberg',
    component_separators = '|',
    section_separators = '',
  },
  sections = {
    lualine_c = { {
      'filename',
      file_status = true,
      path = 1,
    } },
  },
}

-- [[ Comment.nvim ]]

require('Comment').setup()

-- [[ nvim-lastplace ]]

require('nvim-lastplace').setup {
  lastplace_ignore_buftype = { 'quickfix', 'nofile', 'help' },
  lastplace_ignore_filetype = { 'gitcommit', 'gitrebase', 'svn', 'hgcommit' },
  lastplace_open_folds = true,
}

-- [[ Fugitive ]]

vim.keymap.set('n', '<leader>g', ':Git ')

-- [[ git-conflict ]]
require('git-conflict').setup {}

-- [[ oil.nvim ]]
require('oil').setup()

-- [[ Telescope.nvim ]]

require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader>?', builtin.oldfiles)
vim.keymap.set('n', '<leader><space>', builtin.buffers)
vim.keymap.set('n', '<leader>p', builtin.git_files)
vim.keymap.set('n', '<leader>P', builtin.find_files)
vim.keymap.set('n', '<leader>fh', builtin.help_tags)
vim.keymap.set('n', '<leader>fw', builtin.grep_string)
vim.keymap.set('n', '<leader>fs', builtin.live_grep)
vim.keymap.set('n', '<leader>fd', builtin.diagnostics)

-- [[ Harpoon ]]

local mark = require 'harpoon.mark'
local ui = require 'harpoon.ui'

vim.keymap.set('n', '<leader>a', mark.add_file)
vim.keymap.set('n', '<leader>h', ui.toggle_quick_menu)

vim.keymap.set('n', '<leader>j', function()
  ui.nav_file(1)
end)
vim.keymap.set('n', '<leader>k', function()
  ui.nav_file(2)
end)
vim.keymap.set('n', '<leader>l', function()
  ui.nav_file(3)
end)
vim.keymap.set('n', '<leader>;', function()
  ui.nav_file(4)
end)

-- [[ nvim-treesitter ]]
vim.cmd [[highlight link TreesitterContext SignColumn]]

require('nvim-treesitter.configs').setup {
  ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'typescript', 'vimdoc' },

  highlight = { enable = true },
  indent = { enable = true },
}

-- [[ nvim-lspconfig ]]

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)

-- LSP settings.
local on_attach = function(_, bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, bufopts)
end

vim.keymap.set('n', '<leader>=', function()
  vim.lsp.buf.format { timeout_ms = 2000 }
end)

local lspconfig = require 'lspconfig'
local util = require 'lspconfig/util'

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
-- nvim-cmp supports additional completion capabilities
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Lua server
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')

lspconfig.lua_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = runtime_path,
      },
      diagnostics = {
        globals = { 'vim' },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
}

-- html
lspconfig.html.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { 'html', 'htmldjango' },
}

-- tailwind
lspconfig.tailwindcss.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { 'html', 'htmldjango' },
}

-- Python
lspconfig.pyright.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    python = {
      analysis = { typeCheckingMode = 'off' },
    },
  },
  handlers = {
    ['textDocument/publishDiagnostics'] = function() end,
  },
}

-- Golang
lspconfig.gopls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { 'gopls', 'serve' },
  filetypes = { 'go', 'gomod' },
  root_dir = util.root_pattern('go.work', 'go.mod', '.git'),
  settings = { gopls = { analyses = { unusedparams = true }, staticcheck = true } },
}

-- Deno
lspconfig.denols.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern('deno.json', 'deno.jsonc'),
}

-- [[ null-ls.nvim ]]

local null_ls = require 'null-ls'
local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
local ruff_extra_diagnostics_args = { '--extend-select=I,UP', '--extend-ignore=UP007' }
local ruff_extra_formatting_args = { '--extend-select=I,UP', '--extend-ignore=UP006,UP007,F841' }

null_ls.setup {
  on_attach = function(client, bufnr)
    if client.supports_method 'textDocument/formatting' then
      vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format { bufnr = bufnr }
        end,
      })
    end
  end,
  sources = {
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.diagnostics.ruff.with {
      extra_args = ruff_extra_diagnostics_args,
    },
    null_ls.builtins.formatting.ruff.with {
      extra_args = ruff_extra_formatting_args,
    },
    null_ls.builtins.formatting.black.with {
      extra_args = { '--fast' },
    },
    null_ls.builtins.formatting.goimports,
    null_ls.builtins.formatting.prettier.with {
      extra_filetypes = { 'htmldjango' },
    },
    null_ls.builtins.formatting.clang_format,
    null_ls.builtins.formatting.shfmt,
    null_ls.builtins.formatting.trim_newlines,
    null_ls.builtins.formatting.trim_whitespace,
  },
}

-- [[ nvim-cmp ]]
local has_words_before = function()
  unpack = unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil
end

local cmp = require 'cmp'
local luasnip = require 'luasnip'
luasnip.filetype_extend('htmldjango', { 'html' })
require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup {
  completion = {
    autocomplete = false,
  },
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'vim-dadbod-completion' },
  },
}
