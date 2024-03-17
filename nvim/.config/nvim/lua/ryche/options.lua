-- Set highlight on search
vim.o.hlsearch = false

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

-- Tabline
vim.o.showtabline = false

-- Basic indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Decrease update time
vim.opt.updatetime = 50
vim.opt.signcolumn = 'no'
vim.opt.scrolloff = 8

-- Set colorscheme
vim.opt.termguicolors = true
vim.cmd [[colorscheme iceberg]]

-- Set completeopt to have a better completion experience
vim.opt.completeopt = 'menuone,noselect'

-- System clipboard (requires xclip system package)
vim.opt.clipboard = 'unnamedplus'
