local embedded_sql = vim.treesitter.query.parse(
  'python',
  [[
(assignment
  left: (identifier) @var
  right: (string) @sql_var (#contains? @sql_var "--sql"))
(call
  arguments: (argument_list (string) @sql_arg (#contains? @sql_arg "--sql")))
  ]]
)

local get_root = function(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, 'python', {})
  local tree = parser:parse()[1]
  return tree:root()
end

local run_formatter = function(text, indent)
  local split = vim.split(text, '\n')
  local result = table.concat(vim.list_slice(split, 2, #split - 1), '\n')

  local wrap_after = 88 - indent
  local j = require('plenary.job'):new {
    command = 'pg_format',
    args = { '-w', tostring(wrap_after), '-s', '4', '-u', '1', '-f', '1', '-' },
    writer = { result },
  }
  local formatted_text = j:sync()
  local sed_command = "sed 's/\t/    /g'"
  local sed_job = require('plenary.job'):new {
    command = 'bash',
    args = { '-c', sed_command },
    writer = formatted_text,
  }
  return sed_job:sync()
end

local format_sql = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if vim.bo[bufnr].filetype ~= 'python' then
    vim.notify 'can only be used in python'
    return
  end

  local root = get_root(bufnr)

  local changes = {}
  local indent = 0
  for id, node in embedded_sql:iter_captures(root, bufnr, 0, -1) do
    local name = embedded_sql.captures[id]
    local range = { node:range() }
    if name == 'var' or name == 'sql_arg' then
      indent = range[2]
    end
    if name == 'sql_var' or name == 'sql_arg' then
      local formatted = run_formatter(vim.treesitter.get_node_text(node, bufnr), indent)

      local indentation = string.rep(' ', indent)
      for idx, line in ipairs(formatted) do
        formatted[idx] = indentation .. line
      end

      table.insert(changes, 1, {
        start = range[1] + 1,
        final = range[3],
        formatted = formatted,
      })
    end
  end

  for _, change in ipairs(changes) do
    vim.api.nvim_buf_set_lines(bufnr, change.start, change.final, false, change.formatted)
  end
end

vim.api.nvim_create_user_command('SqlMagic', function()
  format_sql()
end, {})

vim.keymap.set('n', '<leader>=', ':SqlMagic<cr>')
