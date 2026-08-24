vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.fillchars = { eob = ' ' }
vim.opt.termguicolors = true

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
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Signcolumn
vim.opt.signcolumn = 'yes'

vim.opt.scrolloff = 10

-- Set completeopt to have a better completion experience
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.shortmess:append 'c'

vim.opt.clipboard = 'unnamedplus'

-- Disable swapfiles
vim.opt.swapfile = false

-- Keymaps for better default experience
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Window navigation with Ctrl + hjkl
vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true, silent = true, desc = 'Move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { noremap = true, silent = true, desc = 'Move to bottom window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { noremap = true, silent = true, desc = 'Move to top window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true, silent = true, desc = 'Move to right window' })

-- Recenter after disorienting jumps
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Splits
vim.keymap.set('n', '<leader>e', ':sp<cr>')
vim.keymap.set('n', '<leader>o', ':vsp<cr>')
vim.keymap.set('n', '<leader>0', ':only<cr>')

-- Buffer actions
vim.keymap.set('n', '<leader>q', ':q<cr>')
vim.keymap.set('n', '<leader>w', ':w<cr>')
vim.keymap.set('n', '<leader><Tab>', '<C-^>')

vim.api.nvim_create_autocmd('CursorMoved', {
  group = vim.api.nvim_create_augroup('auto-hlsearch', { clear = true }),
  callback = function()
    if vim.v.hlsearch == 1 and vim.fn.searchcount().exact_match == 0 then
      vim.schedule(function()
        vim.cmd.nohlsearch()
      end)
    end
  end,
})

-- Highlight when yanking
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Restore cursor position (replaces archived nvim-lastplace)
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('last-place', { clear = true }),
  callback = function(ev)
    local ignore_ft = { gitcommit = true, gitrebase = true, svn = true, hgcommit = true }
    if ignore_ft[vim.bo[ev.buf].filetype] or vim.bo[ev.buf].buftype ~= '' then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

require 'ryche.pack'

require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'auto',
    component_separators = '|',
    section_separators = '',
  },
  sections = {
    lualine_c = { 'tabs', {
      'filename',
      file_status = true,
      path = 1,
    } },
  },
}

require('no-neck-pain').setup {
  width = 120,
  autocmds = { enableOnVimEnter = true },
  mappings = { enabled = true },
}

require('ibl').setup { indent = { char = '▏' }, scope = { enabled = false } }
do
  local hooks = require 'ibl.hooks'
  hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
end

do
  local actions = require 'telescope.actions'

  require('telescope').setup {
    defaults = {
      layout_strategy = 'horizontal',
      layout_config = {
        horizontal = {
          prompt_position = 'top',
        },
      },
      sorting_strategy = 'ascending',
      mappings = {
        i = {
          ['<C-u>'] = false,
          ['<C-d>'] = false,
          ['<C-;>'] = actions.select_default,
        },
        n = {
          ['<C-;>'] = actions.select_default,
        },
      },
    },
    extensions = {
      ['ui-select'] = {
        require('telescope.themes').get_dropdown(),
      },
    },
  }

  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  local builtin = require 'telescope.builtin'

  vim.keymap.set('n', '<leader><leader>', builtin.buffers)
  vim.keymap.set('n', '<leader>f', builtin.git_files)
  vim.keymap.set('n', '<leader>F', builtin.find_files)
  vim.keymap.set('n', '<leader>s', builtin.live_grep)
  vim.keymap.set('n', '<leader>j', builtin.buffers)
  vim.keymap.set('n', '<leader>l', builtin.grep_string)
  vim.keymap.set('v', '<leader>l', builtin.grep_string)
  vim.keymap.set('n', '<leader>.', builtin.resume)
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function()
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', 'gd', builtin.lsp_definitions, { buffer = 0 })
    vim.keymap.set('n', 'gr', builtin.lsp_references, { buffer = 0 })
  end,
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      completion = {
        callSnippet = 'Replace',
      },
      diagnostics = { globals = { 'vim', 'require' }, disable = { 'missing-fields' } },
    },
  },
})
vim.lsp.enable 'lua_ls'

vim.lsp.config('pyright', {
  settings = {
    python = {
      analysis = { typeCheckingMode = 'off' },
    },
  },
  handlers = {
    ['textDocument/publishDiagnostics'] = function() end,
  },
})
vim.lsp.enable 'pyright'

vim.lsp.config('html', {
  filetypes = { 'html', 'htmldjango' },
})
vim.lsp.enable 'html'

vim.lsp.config('cssls', {
  filetypes = { 'css' },
})
vim.lsp.enable 'cssls'

vim.lsp.config('tailwindcss', {
  filetypes = { 'html', 'htmldjango' },
})
vim.lsp.enable 'tailwindcss'

vim.lsp.config('emmet_language_server', {
  filetypes = { 'html', 'htmldjango' },
})
vim.lsp.enable 'emmet_language_server'

vim.lsp.config('ts_ls', {
  filetypes = { 'javascript' },
})
vim.lsp.enable 'ts_ls'

require('blink.cmp').setup {
  keymap = {
    preset = 'default',
    ['<C-;>'] = { 'show', 'select_and_accept' },
    ['<C-space>'] = { 'show_documentation', 'hide_documentation' },
  },
  appearance = {
    nerd_font_variant = 'mono',
  },
  completion = { menu = { auto_show = false }, documentation = { auto_show = false } },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', 'ripgrep' },
    providers = {
      ripgrep = {
        module = 'blink-ripgrep',
        name = 'Ripgrep',
        opts = {},
      },
    },
  },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
}

do
  local lint = require 'lint'
  lint.linters_by_ft = {
    python = { 'ruff', 'mypy' },
  }

  local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
    group = lint_augroup,
    callback = function()
      lint.try_lint()
    end,
  })
end

require('conform').setup {
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_fix', 'ruff_format' },
    sql = { 'sql_formatter' },
    javascript = { 'prettierd', 'prettier', stop_after_first = true },
    json = { 'prettierd', 'prettier', stop_after_first = true },
    css = { 'prettierd', 'prettier', stop_after_first = true },
    html = { 'prettierd', 'prettier', stop_after_first = true },
    htmldjango = { 'prettierd', 'prettier', stop_after_first = true },
    markdown = { 'prettier' },
    sh = { 'shfmt' },
    ['_'] = { 'trim_whitespace', 'trim_newlines' },
  },
  formatters = {
    prettier = {
      prepend_args = { '--prose-wrap', 'always' },
    },
  },
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 500, lsp_fallback = true }
  end,
}

vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
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

do
  local ts = require 'nvim-treesitter'
  ts.setup {}
  ts.install {
    'bash',
    'c',
    'diff',
    'html',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'query',
    'vim',
    'vimdoc',
    'python',
    'typescript',
    'sql',
    'go',
  }

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
    callback = function()
      pcall(vim.treesitter.start)
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end

require('neogit').setup {
  console_timeout = 10000,
}
vim.keymap.set('n', '<leader>gs', ':Neogit<CR>', { silent = true, noremap = true })
vim.keymap.set('n', '<leader>gc', ':Neogit commit<CR>', { silent = true, noremap = true })

require('gitsigns').setup {
  on_attach = function(bufnr)
    local gitsigns = require 'gitsigns'

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        gitsigns.nav_hunk 'next'
      end
    end, { desc = 'Jump to next git [c]hange' })

    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        gitsigns.nav_hunk 'prev'
      end
    end, { desc = 'Jump to previous git [c]hange' })

    map('v', '<leader>hs', function()
      gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, { desc = 'stage git hunk' })
    map('v', '<leader>hr', function()
      gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, { desc = 'reset git hunk' })
    map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
    map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
    map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
    map('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'git [u]ndo stage hunk' })
    map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
    map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
    map('n', '<leader>hb', gitsigns.blame, { desc = 'git [b]lame' })
    map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
    map('n', '<leader>hD', function()
      gitsigns.diffthis '@'
    end, { desc = 'git [D]iff against last commit' })
    map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
    map('n', '<leader>tD', gitsigns.toggle_deleted, { desc = '[T]oggle git show [D]eleted' })
  end,
}

require('oil').setup {}
vim.keymap.set('n', '<leader>-', ':Oil<CR>', { silent = true, noremap = true })

require('quicker').setup {}

require('mini.surround').setup {
  mappings = {
    add = 'yz',
    delete = 'dz',
    find = '',
    find_left = '',
    highlight = '',
    replace = 'cz',
    update_n_lines = '',
    suffix_last = '',
    suffix_next = '',
  },
  search_method = 'cover_or_next',
}
require('mini.pairs').setup {}

do
  local hipatterns = require 'mini.hipatterns'
  hipatterns.setup {
    highlighters = {
      fixme = { pattern = '%f[%w]()FIX()%f[%W]', group = 'MiniHipatternsFixme' },
      hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
      todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
      note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  }
end

do
  local bufremove = require 'mini.bufremove'
  bufremove.setup {}
  vim.keymap.set('n', '<leader>d', function()
    bufremove.delete(0, false)
  end, { noremap = true, silent = true })
  vim.keymap.set('n', '<leader>D', function()
    bufremove.delete(0, true)
  end, { noremap = true, silent = true })
end

require('nvim-ts-autotag').setup()

vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap)')
vim.keymap.set('n', 'S', '<Plug>(leap-from-window)')
require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }
vim.api.nvim_set_hl(0, 'LeapLabel', { link = 'Search' })

require('ryche.omarchy').setup()
