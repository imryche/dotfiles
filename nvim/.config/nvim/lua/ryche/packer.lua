local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'
local is_bootstrap = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  is_bootstrap = true
  vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
  vim.cmd [[packadd packer.nvim]]
end

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use 'neovim/nvim-lspconfig'
  use 'mfussenegger/nvim-lint'
  use 'stevearc/conform.nvim'

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
  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
    after = 'nvim-treesitter',
  }
  use 'nvim-treesitter/nvim-treesitter-context'

  use 'tpope/vim-fugitive'
  use 'akinsho/git-conflict.nvim'

  use 'stevearc/oil.nvim'

  use 'cocopon/iceberg.vim'
  use 'nvim-lualine/lualine.nvim'
  use 'numToStr/Comment.nvim'
  use 'sheerun/vim-polyglot'
  use 'ethanholz/nvim-lastplace'
  use 'famiu/bufdelete.nvim'
  use 'windwp/nvim-autopairs'
  use 'windwp/nvim-ts-autotag'
  use 'mg979/vim-visual-multi'
  use { 'folke/todo-comments.nvim', requires = { 'nvim-lua/plenary.nvim' } }

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
