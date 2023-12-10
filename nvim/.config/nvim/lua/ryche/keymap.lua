-- Keymaps for better default experience
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Switch windows faster
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Recenter after disorienting jumps
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Splits
vim.keymap.set('n', '<leader>S', ':sp<cr>')
vim.keymap.set('n', '<leader>s', ':vsp<cr>')
vim.keymap.set('n', '<leader>o', ':only<cr>')

-- Open file directory
vim.keymap.set('n', '<leader>d', ':Oil<cr>')

-- Buffer actions
vim.keymap.set('n', '<leader>x', ':bd<cr>')
vim.keymap.set('n', '<leader>q', ':q<cr>')
vim.keymap.set('n', '<leader>w', ':w<cr>')
vim.keymap.set('n', "<leader>'", '<C-^>')

-- Dadbod
vim.keymap.set('n', '<leader>c', ':DBUIToggle<cr>')
