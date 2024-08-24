-- Line numbers
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.cursorline = true

-- Basic indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Search
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Decrease update time
vim.opt.updatetime = 50

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Signcolumn
vim.opt.signcolumn = 'yes'

vim.opt.scrolloff = 10

-- Set colorscheme
vim.cmd 'colorscheme iceberg'

-- Set completeopt to have a better completion experience
vim.opt.completeopt = 'menuone,noselect'

-- System clipboard (requires xclip system package)
vim.opt.clipboard = 'unnamedplus'
