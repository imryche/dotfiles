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

vim.keymap.set('n', '<leader><space>', builtin.buffers)
vim.keymap.set('n', '<C-p>', builtin.git_files)
vim.keymap.set('n', '<C-M-p>', builtin.find_files)
vim.keymap.set('n', '<leader>?', builtin.grep_string)
vim.keymap.set('n', '<leader>/', builtin.live_grep)
vim.keymap.set('n', '<leader>.', builtin.resume)
