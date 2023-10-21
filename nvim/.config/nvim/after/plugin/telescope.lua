local telescope_theme = 'ivy'
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
  pickers = {
    buffers = { theme = telescope_theme },
    git_files = { theme = telescope_theme },
    find_files = { theme = telescope_theme },
    grep_string = { theme = telescope_theme },
    live_grep = { theme = telescope_theme },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader><space>', builtin.buffers)
vim.keymap.set('n', '<C-p>', builtin.git_files)
vim.keymap.set('n', '<C-M-p>', builtin.find_files)
vim.keymap.set('n', '<leader>?', builtin.grep_string)
vim.keymap.set('n', '<leader>/', builtin.live_grep)
