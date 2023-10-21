require('lint').linters_by_ft = {
  python = { 'ruff' },
  -- sql = { 'sqlfluff' },
}

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave', 'TextChanged' }, {
  callback = function()
    require('lint').try_lint()
  end,
})
