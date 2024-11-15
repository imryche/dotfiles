vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

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
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Signcolumn
vim.opt.signcolumn = 'yes'

vim.opt.scrolloff = 10

-- Set completeopt to have a better completion experience
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.shortmess:append 'c'

-- System clipboard (requires xclip system package)
vim.opt.clipboard = 'unnamedplus'

-- Disable swapfiles
vim.opt.swapfile = false

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

-- Buffer actions
vim.keymap.set('n', '<leader>q', ':q<cr>')
vim.keymap.set('n', '<leader>w', ':w<cr>')
vim.keymap.set('n', '<leader><Tab>', '<C-^>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)

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
    vim.highlight.on_yank()
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
  -- Colorscheme
  {
    'zenbones-theme/zenbones.nvim',
    dependencies = 'rktjmp/lush.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'zenbones'
    end,
  },
  { 'ellisonleao/glow.nvim', config = true, cmd = 'Glow' },
  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        theme = 'zenbones',
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
    },
  },
  -- Indent guides
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    config = function()
      require('ibl').setup { indent = { char = '▏' }, scope = { enabled = false } }
      local hooks = require 'ibl.hooks'
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
    end,
  },
  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
    },
    config = function()
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
            },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'

      vim.keymap.set('n', '<leader><leader>', builtin.buffers)
      vim.keymap.set('n', '<leader>f', builtin.git_files)
      vim.keymap.set('n', '<leader>F', builtin.find_files)
      vim.keymap.set('n', '<leader>,', builtin.grep_string)
      vim.keymap.set('n', '<leader>.', builtin.resume)
      vim.keymap.set('n', '<leader>/', builtin.live_grep)
    end,
  },
  -- LSP
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('K', vim.lsp.buf.hover, 'Symbol info')
          map('<C-s>', vim.lsp.buf.signature_help, 'Signature help', 'i')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
      capabilities.textDocument.completion.completionItem.snippetSupport = true

      local util = require 'lspconfig/util'

      local runtime_path = vim.split(package.path, ';')
      table.insert(runtime_path, 'lua/?.lua')
      table.insert(runtime_path, 'lua/?/init.lua')

      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              diagnostics = { globals = { 'vim', 'require' }, disable = { 'missing-fields' } },
            },
          },
        },
        html = {
          filetypes = { 'html', 'htmldjango' },
        },
        cssls = {
          filetypes = { 'css' },
        },
        tailwindcss = {
          filetypes = { 'html', 'htmldjango' },
        },
        emmet_ls = {
          filetypes = { 'html', 'htmldjango' },
        },
        pyright = {
          settings = {
            python = {
              analysis = { typeCheckingMode = 'off' },
            },
          },
          handlers = {
            ['textDocument/publishDiagnostics'] = function() end,
          },
        },
        gopls = {
          cmd = { 'gopls', 'serve' },
          filetypes = { 'go', 'gomod' },
          root_dir = util.root_pattern('go.work', 'go.mod', '.git'),
          settings = { gopls = { analyses = { unusedparams = true }, staticcheck = true } },
        },
        eslint = {
          filetypes = { 'javascript' },
        },
        ts_ls = {
          filetypes = { 'javascript' },
        },
        denols = {
          root_dir = util.root_pattern('deno.json', 'deno.jsonc'),
        },
      }

      require('mason').setup()
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua',
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
  -- Autocompletion
  {
    'hrsh7th/nvim-cmp',
    lazy = false,
    priority = 100,
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          {
            'rafamadriz/friendly-snippets',
            config = function()
              require('luasnip.loaders.from_vscode').lazy_load()
            end,
          },
        },
      },
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.filetype_extend('htmldjango', { 'html' })

      cmp.setup {
        completion = {
          keyword_length = 3,
        },
        sources = {
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' },
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item { behaviour = cmp.SelectBehavior.Insert },
          ['<C-p>'] = cmp.mapping.select_prev_item { behaviour = cmp.SelectBehavior.Insert },
          ['<C-y>'] = cmp.mapping(cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Insert, select = true }, { 'i', 'c' }),
          ['<C-Space>'] = cmp.mapping.complete(),
        },
      }
    end,
  },
  -- Linting
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        python = { 'ruff' },
      }

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
  -- Autoformat
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'ruff_fix', 'ruff_format' },
        sql = { 'pg_format' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        htmldjango = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettier' },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        sh = { 'shfmt' },
        ['_'] = { 'trim_whitespace', 'trim_newlines' },
      },
      formatters = {
        pg_format = {
          prepend_args = { '-g', '-s', '4', '-u', '1', '-f', '1' },
        },
        prettier = {
          prepend_args = { '--prose-wrap', 'always' },
        },
      },
      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
    },
    init = function()
      vim.api.nvim_create_user_command('FormatDisable', function(args)
        if args.bang then
          -- FormatDisable! will disable formatting just for this buffer
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
    end,
  },
  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'nvim-treesitter/nvim-treesitter-context',
    },
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
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
      },
      auto_install = true,
      -- highlight = {
      --   enable = true,
      -- },
      indent = { enable = true },
    },
    -- config = function()
    --   vim.cmd [[highlight! link TreesitterContext SignColumn]]
    -- end,
  },
  -- Git
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('neogit').setup {
        console_timeout = 10000,
      }
      vim.keymap.set('n', '<leader>gs', ':Neogit<CR>', { silent = true, noremap = true })
      vim.keymap.set('n', '<leader>gc', ':Neogit commit<CR>', { silent = true, noremap = true })
    end,
  },
  -- Visual diff
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
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

        -- Actions
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
    },
  },
  -- Files
  {
    'stevearc/oil.nvim',
    lazy = false,
    config = function()
      require('oil').setup {}
      vim.keymap.set('n', '<leader>-', ':Oil<CR>', { silent = true, noremap = true })
    end,
  },
  -- Databases
  {
    'kndndrj/nvim-dbee',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    build = function()
      require('dbee').install()
    end,
    config = function()
      require('dbee').setup {
        sources = {
          require('dbee.sources').MemorySource:new {
            {
              name = 'reacto',
              type = 'sqlite',
              url = '~/proj/reacto/reacto.db',
            },
          },
        },
      }
    end,
  },
  -- Remember position in buffer
  {
    'ethanholz/nvim-lastplace',
    opts = {
      lastplace_ignore_buftype = { 'quickfix', 'nofile', 'help' },
      lastplace_ignore_filetype = { 'gitcommit', 'gitrebase', 'svn', 'hgcommit' },
      lastplace_open_folds = true,
    },
  },
  -- Mini
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.sessions').setup {
        autoread = true,
      }
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

      local hipatterns = require 'mini.hipatterns'
      hipatterns.setup {
        highlighters = {
          -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
          fixme = { pattern = '%f[%w]()FIX()%f[%W]', group = 'MiniHipatternsFixme' },
          hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
          todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
          note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
          -- Highlight hex color strings (`#rrggbb`) using that color
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      }

      require('mini.comment').setup {}
      local bufremove = require 'mini.bufremove'
      bufremove.setup {}
      vim.keymap.set('n', '<leader>d', function()
        bufremove.delete(0, false)
      end, { noremap = true, silent = true })
      vim.keymap.set('n', '<leader>D', function()
        bufremove.delete(0, true)
      end, { noremap = true, silent = true })
    end,
  },
  -- Autotags
  { 'windwp/nvim-ts-autotag', event = 'InsertEnter', config = true },
  -- Multicursor
  { 'mg979/vim-visual-multi' },
  -- Bracket mappings
  { 'tpope/vim-unimpaired' },
  -- Autodetect indent
  { 'tpope/vim-sleuth' },
  -- Jump in visible area quickly
  {
    'ggandor/leap.nvim',
    config = function()
      vim.keymap.set('n', 's', '<Plug>(leap)')
      vim.keymap.set('n', 'S', '<Plug>(leap-from-window)')
      vim.keymap.set({ 'x', 'o' }, 's', '<Plug>(leap-forward)')
      vim.keymap.set({ 'x', 'o' }, 'S', '<Plug>(leap-backward)')

      -- Define equivalence classes for brackets and quotes, in addition to
      -- the default whitespace group.
      require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }

      vim.api.nvim_set_hl(0, 'LeapLabel', { link = 'Search' })
    end,
  },
}

local function get_current_context()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = vim.api.nvim_get_current_line()

  -- get the current buffer
  local bufnr = vim.api.nvim_get_current_buf()

  -- get the parser
  local parser = vim.treesitter.get_parser(bufnr)
  local tree = parser:parse()[1]
  local root = tree:root()

  -- get the node at current position
  local node = root:named_descendant_for_range(cursor_pos[1] - 1, cursor_pos[2], cursor_pos[1] - 1, cursor_pos[2])

  -- get the text of the node under the cursor
  local node_text = vim.treesitter.get_node_text(node, bufnr)

  -- find the closes function node
  local current_node = node
  while current_node do
    if current_node:type() == 'function_declaration' or current_node:type() == 'function_definition' or current_node:type() == 'local_function' then
      break
    end
    current_node = current_node:parent()
  end

  if not current_node then
    return nil
  end

  -- get the range of the function
  local start_row, _, end_row, _ = current_node:range()

  -- get the function text
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  local function_text = table.concat(lines, '\n')

  return {
    node_text = node_text,
    current_line = current_line,
    function_text = function_text,
  }
end

local function ask_llm()
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  local start_col = vim.fn.col "'<"
  local end_col = vim.fn.col "'>"

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  local selected_text = ''
  if #lines == 1 then
    selected_text = string.sub(lines[1], start_col, end_col)
  else
    selected_text = string.sub(lines[1], start_col)
    for i = 2, #lines - 1 do
      selected_text = selected_text .. '\n' .. lines[i]
    end
    selected_text = selected_text .. '\n' .. string.sub(lines[#lines], 1, end_col)
  end

  print(selected_text)

  -- get context using treesitter
  local context = get_current_context()
  local context_text = selected_text
  if context then
    context_text =
      string.format('Current line:\n%s\n\nSelected text:\n%s\n\nEnclosing function:\n%s\n', context.current_line, context.node_text, context.function_text)
  end
  print(context_text)

  local prompt = vim.fn.input 'Ask something: '
  local command = string.format("llm -m claude-3.5-sonnet '%s'", prompt)

  local output_data = ''

  local function on_output(_, data, _)
    if data then
      output_data = output_data .. table.concat(data, '\n') .. '\n'
    end
  end

  local function on_exit(_, exit_code)
    vim.schedule(function()
      if exit_code ~= 0 then
        vim.notify('Error: LLM command failed', vim.log.levels.ERROR)
        return
      end

      local current_win = vim.api.nvim_get_current_win()

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

      local window_count = #vim.api.nvim_tabpage_list_wins(0)

      if window_count == 1 then
        vim.api.nvim_command 'botright vsplit'
      else
        vim.api.nvim_command 'belowright split'
      end

      local new_win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(new_win, buf)

      local output_lines = vim.split(output_data, '\n')
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)

      vim.schedule(function()
        vim.notify('Done.', vim.log.levels.INFO)
      end)

      vim.api.nvim_set_current_win(current_win)
    end)
  end

  local chan = vim.fn.jobstart(command, {
    on_stdout = on_output,
    on_stderr = on_output,
    on_exit = on_exit,
    stdout_buffered = true,
    stderr_buffered = true,
  })

  vim.fn.chansend(chan, context_text)
  vim.fn.chanclose(chan, 'stdin')

  vim.schedule(function()
    vim.notify('Thinking...', vim.log.levels.INFO)
  end)
end

vim.api.nvim_create_user_command('Ask', ask_llm, { range = true })
vim.api.nvim_set_keymap('v', '<leader>a', ':Ask<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>a', ':Ask<CR>', { noremap = true, silent = true })
