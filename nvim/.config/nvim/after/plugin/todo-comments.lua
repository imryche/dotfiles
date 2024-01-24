require('todo-comments').setup()

vim.keymap.set('n', '<leader>tt', ':TodoTelescope keywords=TODO<cr>')
vim.keymap.set('n', '<leader>tf', ':TodoTelescope keywords=FIX<cr>')
vim.keymap.set('n', '<leader>tw', ':TodoTelescope keywords=WARN<cr>')
vim.keymap.set('n', '<leader>th', ':TodoTelescope keywords=HACK<cr>')
