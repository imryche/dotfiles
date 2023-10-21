require('nvim-treesitter.configs').setup {
  ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'typescript', 'vimdoc' },
  autotag = { enable = true },
  highlight = { enable = true },
  indent = { enable = true },
}

vim.cmd [[highlight link TreesitterContext SignColumn]]
