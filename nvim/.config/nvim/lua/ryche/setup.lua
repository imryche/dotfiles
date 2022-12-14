-- Set up lualine
require('lualine').setup {
    options = {
        section_separators = '',
        component_separators = '',
        theme = 'iceberg'
    }
}

-- Set up nvim-treesitter
require('nvim-treesitter.configs').setup {
    ensure_installed = {"c", "lua", "python"},
    sync_install = false,
    auto_install = true,
    ignore_install = {"javascript"},

    highlight = {
        enable = true,
        disable = {},
        additional_vim_regex_highlighting = false
    }
}

-- Set up telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<leader>ps', builtin.live_grep, {})
vim.keymap.set('n', '<leader>pw', function()
    builtin.grep_string({search = vim.fn.expand("<cword>")})
end, {})

-- Set up harpoon
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<leader>h", ui.toggle_quick_menu)

vim.keymap.set("n", "<leader>j", function() ui.nav_file(1) end)
vim.keymap.set("n", "<leader>k", function() ui.nav_file(2) end)
vim.keymap.set("n", "<leader>l", function() ui.nav_file(3) end)
vim.keymap.set("n", "<leader>;", function() ui.nav_file(4) end)

-- Set up nvim-cmp
local cmp = require 'cmp'

cmp.setup({
    snippet = {},
    window = {},
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({select = true})
    }),
    sources = cmp.config.sources({{name = 'nvim_lsp'}}, {{name = 'buffer'}})
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Set up ale
vim.g.ale_fix_on_save = 1
vim.g.ale_fixers = {
    ['*'] = {'remove_trailing_lines', 'trim_whitespace'},
    ['c'] = {'clang-format'},
    ['json'] = {'jq'},
    ['lua'] = {'lua-format'},
    ['python'] = {'isort', 'black'}
}
vim.g.ale_linters = {['python'] = {'flake8'}}
vim.keymap.set("n", "gj", ":ALENextWrap<cr>")
vim.keymap.set("n", "gk", ":ALEPreviousWrap<cr>")

-- Set up lspconfig.
local opts = {noremap = true, silent = true}

local on_attach = function(client, bufnr)
    -- Mappings.
    local bufopts = {noremap = true, silent = true, buffer = bufnr}
    vim.keymap.set('n', '<space>.', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
end

lspconfig = require "lspconfig"
util = require "lspconfig/util"

lspconfig.pyright.setup {
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = capabilities
}

lspconfig.gopls.setup {
    on_attach = on_attach,
    cmd = {"gopls", "serve"},
    filetypes = {"go", "gomod"},
    root_dir = util.root_pattern("go.work", "go.mod", ".git"),
    settings = {gopls = {analyses = {unusedparams = true}, staticcheck = true}}
}

vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
