require('telescope').setup {
  defaults = {
    layout_strategy = 'horizontal',
    layout_config = {
      horizontal = {
        prompt_position = 'top',
      },
    },
    sorting_strategy = 'ascending',
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

vim.keymap.set('n', '<leader><leader>', builtin.buffers)
vim.keymap.set('n', '<leader>f', builtin.git_files)
vim.keymap.set('n', '<leader>F', builtin.find_files)
vim.keymap.set('n', '<leader>?', builtin.grep_string)
vim.keymap.set('n', '<leader>/', builtin.live_grep)
vim.keymap.set('n', '<leader>.', builtin.resume)
vim.keymap.set('n', 'gr', builtin.lsp_references)
vim.keymap.set('n', 'gd', builtin.lsp_definitions)
