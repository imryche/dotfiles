require('neogit').setup {}

vim.keymap.set('n', '<leader>gs', ':Neogit<CR>', { silent = true, noremap = true })
vim.keymap.set('n', '<leader>gc', ':Neogit commit<CR>', { silent = true, noremap = true })
vim.keymap.set('n', '<leader>gp', ':Neogit pull<CR>', { silent = true, noremap = true })
vim.keymap.set('n', '<leader>gP', ':Neogit push<CR>', { silent = true, noremap = true })
vim.keymap.set('n', '<leader>gb', ':Telescope git_branches<CR>', { silent = true, noremap = true })
