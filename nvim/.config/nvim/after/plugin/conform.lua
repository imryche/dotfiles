require('conform').setup {
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_fix', 'ruff_format' },
    sql = { 'pg_format' },
    javascript = { 'prettierd', 'prettier', stop_after_first = true },
    json = { 'prettierd', 'prettier', stop_after_first = true },
    html = { 'prettierd', 'prettier', stop_after_first = true },
    htmldjango = { 'prettierd', 'prettier', stop_after_first = true },
    markdown = { 'prettier' },
    yaml = { 'prettierd', 'prettier', stop_after_first = true },
    sh = { 'shfmt' },
    ['_'] = { 'trim_whitespace', 'trim_newlines' },
  },
  formatters = {
    pg_format = {
      prepend_args = { '-g', '-s', '4', '-u', '1', '-f', '1' },
    },
    prettier = {
      prepend_args = { '--prose-wrap', 'always' },
    },
  },
  format_on_save = function(bufnr)
    -- Disable with a global or buffer-local variable
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 500, lsp_fallback = true }
  end,
}

vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = 'Disable autoformat-on-save',
  bang = true,
})

vim.api.nvim_create_user_command('FormatEnable', function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = 'Re-enable autoformat-on-save',
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = '*.html',
  callback = function()
    vim.bo.filetype = 'html'
  end,
})
