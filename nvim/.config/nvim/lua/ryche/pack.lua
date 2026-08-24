-- Native plugin manager (Neovim 0.12 vim.pack). No lazy.nvim.
-- Update:  :lua vim.pack.update()
-- Remove leftovers from disk after dropping a spec: :lua vim.pack.del({ 'name' })

local function gh(repo)
  return 'https://github.com/' .. repo
end

-- Build hooks must be registered before the first vim.pack.add().
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('pack-hooks', { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'telescope-fzf-native.nvim' and (kind == 'install' or kind == 'update') then
      vim.system({ 'make' }, { cwd = ev.data.path }):wait()
    end
  end,
})

vim.pack.add({
  { src = gh 'bjarneo/aether.nvim', name = 'aether', version = 'v3' },
  gh 'nvim-lualine/lualine.nvim',
  gh 'lukas-reineke/indent-blankline.nvim',
  gh 'nvim-lua/plenary.nvim',
  { src = gh 'nvim-telescope/telescope.nvim', version = 'master' },
  gh 'nvim-telescope/telescope-fzf-native.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
  gh 'neovim/nvim-lspconfig',
  { src = gh 'saghen/blink.cmp', version = vim.version.range '1' },
  gh 'rafamadriz/friendly-snippets',
  gh 'mikavilpas/blink-ripgrep.nvim',
  gh 'mfussenegger/nvim-lint',
  gh 'stevearc/conform.nvim',
  { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' },
  gh 'nvim-treesitter/nvim-treesitter-context',
  gh 'NeogitOrg/neogit',
  gh 'sindrets/diffview.nvim',
  gh 'lewis6991/gitsigns.nvim',
  gh 'stevearc/oil.nvim',
  gh 'stevearc/quicker.nvim',
  gh 'echasnovski/mini.nvim',
  gh 'windwp/nvim-ts-autotag',
  gh 'tpope/vim-sleuth',
  { src = 'https://codeberg.org/andyg/leap.nvim', name = 'leap.nvim' },
}, { confirm = false, load = true })
