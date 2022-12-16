-- Set up lualine
require("lualine").setup({
	options = {
		section_separators = "",
		component_separators = "",
		theme = "iceberg",
	},
})

-- Set up nvim-treesitter
require("nvim-treesitter.configs").setup({
	ensure_installed = { "c", "lua", "python" },
	sync_install = false,
	auto_install = true,
	ignore_install = { "javascript" },

	highlight = {
		enable = true,
		disable = {},
		additional_vim_regex_highlighting = false,
	},
})

-- Set up telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<C-p>", builtin.git_files, {})
vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
vim.keymap.set("n", "<leader>ps", builtin.live_grep, {})
vim.keymap.set("n", "<leader>pw", function()
	builtin.grep_string({ search = vim.fn.expand("<cword>") })
end, {})

-- Set up harpoon
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<leader>h", ui.toggle_quick_menu)

vim.keymap.set("n", "<leader>j", function()
	ui.nav_file(1)
end)
vim.keymap.set("n", "<leader>k", function()
	ui.nav_file(2)
end)
vim.keymap.set("n", "<leader>l", function()
	ui.nav_file(3)
end)
vim.keymap.set("n", "<leader>;", function()
	ui.nav_file(4)
end)

-- Set up nvim-cmp
local cmp = require("cmp")

cmp.setup({
	snippet = {},
	window = {},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({ { name = "nvim_lsp" } }, { { name = "buffer" } }),
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Set up ale
-- vim.g.ale_fixers = {
-- 	["*"] = { "remove_trailing_lines", "trim_whitespace" },
-- 	["c"] = { "clang-format" },
-- 	["json"] = { "jq" },
-- 	["python"] = { "isort", "black" },
-- }
-- vim.g.ale_linters = { ["python"] = { "flake8" } }
-- vim.keymap.set("n", "gj", ":ALENextWrap<cr>")
-- vim.keymap.set("n", "gk", ":ALEPreviousWrap<cr>")

-- Set up lspconfig.
local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<leader>i", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "gj", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "gk", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "<leader>o", vim.diagnostic.setloclist, opts)

local on_attach = function(client, bufnr)
	-- Mappings.
	local bufopts = { noremap = true, silent = true, buffer = bufnr }
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
end

lspconfig = require("lspconfig")
util = require("lspconfig/util")

lspconfig.sumneko_lua.setup({
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = { "vim" },
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = {
				enable = false,
			},
		},
	},
})

lspconfig.pyright.setup({
	on_attach = on_attach,
	flags = lsp_flags,
	capabilities = capabilities,
	settings = { python = { analysis = { typeCheckingMode = "off" } } },
})

lspconfig.gopls.setup({
	on_attach = on_attach,
	cmd = { "gopls", "serve" },
	filetypes = { "go", "gomod" },
	root_dir = util.root_pattern("go.work", "go.mod", ".git"),
	settings = { gopls = { analyses = { unusedparams = true }, staticcheck = true } },
})

-- Set up null-ls
local null_ls = require("null-ls")

null_ls.setup({
	sources = {
		null_ls.builtins.formatting.stylua,
        null_ls.builtins.diagnostics.pylint,
		null_ls.builtins.formatting.isort,
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.prettier,
		null_ls.builtins.formatting.clang_format,
		null_ls.builtins.formatting.trim_newlines,
		null_ls.builtins.formatting.trim_whitespace,
	},
})
vim.keymap.set("n", "<leader>f", function()
	vim.lsp.buf.format({ timeout_ms = 2000 })
end)
