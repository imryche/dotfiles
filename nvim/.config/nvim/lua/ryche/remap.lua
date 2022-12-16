vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "<leader>o", "<C-^>")

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader>1", ":only<cr>")
vim.keymap.set("n", "<leader>2", ":sp<cr>")
vim.keymap.set("n", "<leader>3", ":vsp<cr>")

vim.keymap.set("n", "<leader>s", ":w<cr>")

vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

vim.keymap.set("n", "<leader>q", ":bd<cr>")
