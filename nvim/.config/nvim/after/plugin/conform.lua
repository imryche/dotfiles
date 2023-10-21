require('conform').setup {
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_fix', 'black' },
    sql = { 'sql_formatter' },
    javascript = { { 'prettierd', 'prettier' } },
    json = { { 'prettierd', 'prettier' } },
    html = { { 'prettierd', 'prettier' } },
    htmldjango = { { 'prettierd', 'prettier' } },
    ['_'] = { 'trim_whitespace', 'trim_newlines' },
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
