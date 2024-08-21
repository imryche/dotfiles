require('nvim-treesitter.configs').setup {
  ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'sql', 'typescript', 'vimdoc', 'html' },
  highlight = { enable = true },
  indent = { enable = true },
}

vim.cmd [[highlight! link TreesitterContext SignColumn]]

require('nvim-ts-autotag').setup {}
