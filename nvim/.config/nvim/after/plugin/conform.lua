require('conform').setup {
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_fix', 'ruff_format' },
    sql = { 'pg_format' },
    javascript = { { 'prettierd', 'prettier' } },
    json = { { 'prettierd', 'prettier' } },
    html = { { 'prettierd', 'prettier' } },
    htmldjango = { { 'prettierd', 'prettier' } },
    yaml = { { 'prettierd', 'prettier' } },
    sh = { 'shfmt' },
    ['_'] = { 'trim_whitespace', 'trim_newlines' },
  },
  formatters = {
    pg_format = {
      prepend_args = { '-s', '4', '-u', '1', '-f', '1' },
    },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = '*.html',
  callback = function()
    vim.bo.filetype = 'html'
  end,
})
