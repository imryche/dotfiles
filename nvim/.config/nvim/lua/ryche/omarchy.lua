-- Paint nvim from the current Omarchy palette (colors.toml) via aether.
-- No LazyVim, no per-theme colorscheme plugins.

local M = {}

local COLORS_FILE = vim.fn.expand '~/.local/state/omarchy/current/theme/colors.toml'
local THEME_NAME_FILE = vim.fn.expand '~/.local/state/omarchy/current/theme.name'
local THEME_DIR = vim.fn.expand '~/.local/state/omarchy/current/theme'
local CURRENT_DIR = vim.fn.expand '~/.local/state/omarchy/current'

-- aether.setup()/load() always register an Omarchy neovim.lua watcher that
-- tries to :colorscheme the LazyVim spec in that file. Mark hotreload as
-- already initialized so we own reloads from colors.toml instead.
_G.__aether_hotreload_state = _G.__aether_hotreload_state or {
  did_setup = true,
  fs_event_handles = {},
  pending_reload_timers = {},
}

local applying = false
local apply_timer
local watches = {}

local function read_palette()
  local colors, mode = {}, 'dark'
  if vim.fn.filereadable(COLORS_FILE) == 0 then
    return colors, mode
  end

  local text
  local ok, sys = pcall(function()
    return vim.system({ 'omarchy-theme-color', '--file', COLORS_FILE, '--all' }, { text = true }):wait()
  end)
  if ok and sys and sys.code == 0 and sys.stdout and sys.stdout ~= '' then
    text = sys.stdout
  else
    local f = io.open(COLORS_FILE, 'r')
    if f then
      text = f:read '*a'
      f:close()
    end
  end

  if not text then
    return colors, mode
  end

  for line in text:gmatch '[^\n]+' do
    local key, value = line:match '^([%w_]+)\t(.+)$'
    if not key then
      key, value = line:match '^([%w_]+)%s*=%s*"(.-)"'
    end
    if key == 'mode' or key == 'theme_type' then
      if value == 'light' or value == 'dark' then
        mode = value
      end
    elseif key and value and value:match '^#%x+$' then
      colors[key] = value
    end
  end

  return colors, mode
end

function M.apply()
  if applying then
    return
  end
  applying = true

  local colors, mode = read_palette()
  vim.o.termguicolors = true
  vim.o.background = mode

  local ok, aether = pcall(require, 'aether')
  if not ok then
    applying = false
    vim.notify('Omarchy theme: aether.nvim is not available', vim.log.levels.WARN)
    return
  end

  aether.setup { colors = colors }
  aether.load()
  applying = false
end

function M.schedule_apply()
  if apply_timer then
    apply_timer:stop()
    apply_timer:close()
  end
  apply_timer = vim.uv.new_timer()
  apply_timer:start(200, 0, vim.schedule_wrap(function()
    if apply_timer then
      apply_timer:stop()
      apply_timer:close()
      apply_timer = nil
    end
    M.apply()
  end))
end

local function watch(path)
  local uv = vim.uv or vim.loop
  if not uv or not uv.new_fs_event then
    return
  end
  if vim.fn.filereadable(path) ~= 1 and vim.fn.isdirectory(path) ~= 1 then
    return
  end

  local handle = uv.new_fs_event()
  if not handle then
    return
  end

  local started = handle:start(path, {}, vim.schedule_wrap(function()
    M.schedule_apply()
  end))
  if started == 0 or started == true then
    table.insert(watches, handle)
  else
    handle:close()
  end
end

function M.setup()
  M.apply()

  watch(THEME_NAME_FILE)
  watch(THEME_DIR)
  watch(CURRENT_DIR)

  vim.api.nvim_create_user_command('OmarchyTheme', M.apply, {
    desc = 'Re-apply the current Omarchy palette',
  })
end

return M
