local dap = require("dap")
local config = require("debugmaster.config")
local utils = require("debugmaster.utils")
local widgets = require('dap.ui.widgets')
local repl = require 'dap.repl'

local M = {}

--- Debug adapter interface
---@class debugmaster.Dapi
local Dapi = {}

---@class debugmaster.Dapi.Component
---@field buf number
---@field name string

function M.new(term_buf)
  ---@class debugmaster.Dapi
  local self = setmetatable({}, { __index = Dapi })
  self.hints_ns = vim.api.nvim_create_namespace("dapi-hints")
  self.main_win = nil
  self.direction = "right"
  self.float = false

  local repl_buf, repl_win = repl.open()
  ---@type debugmaster.Dapi.Component
  self.repl = {buf = repl_buf, name = "[R]epl"}
  vim.api.nvim_win_close(repl_win, true)

  local scopes = widgets.sidebar(widgets.scopes)
  local scopes_buf, scopes_win = scopes.open()
  ---@type debugmaster.Dapi.Component
  self.scopes = {buf = scopes_buf, name = "[S]copes"}
  vim.api.nvim_win_close(scopes_win, true)
  vim.api.nvim_buf_set_keymap(scopes_buf, "n", "q", "<cmd>q<CR>", {})

  ---@type debugmaster.Dapi.Component
  self.terminal = {buf = term_buf, name = "[O]utput"}

  ---@type debugmaster.Dapi.Component
  self.active = self.scopes

  return self
end

function Dapi:toggle()
  if not utils.is_win_valid(self.main_win) then
    self:open()
  else
    self:close()
  end
end

---@class debugmaster.Dapi.OpenOptions
---@field direction "left" | "right" | "above" | "below" | nil Opens in previous state if nil (right when open first time)
---@field float boolean? If float specified then it creates float window and ignore direction

---@param opts debugmaster.Dapi.OpenOptions?
function Dapi:open(opts)
  if not self.scopes.buf then
    return print("Can't open dapi. Debug session is not active")
  elseif utils.is_win_valid(self.main_win)  then
    return
  end

  -- preparing new options (float, direction)
  opts = opts or {}
  local float = self.float
  if opts.float ~= nil then
    float = opts.float
  end
  local direction = opts.direction or self.direction
  ---@type vim.api.keyset.win_config
  local cfg = {}
  local enter = false

  if float then
    cfg = utils.make_center_float_win_cfg()
    enter = true
  else
    cfg.split = direction
  end

  --  it saves us if we try open it in a float window
  local ok, res = pcall(vim.api.nvim_open_win, self.scopes.buf, enter, cfg)
  if not ok then
    return
  end

  -- Applying new options (if pcall successfull)
  self.main_win = res
  self.direction = direction
  self.float = float
  vim.api.nvim_set_option_value("number", false, {win = self.main_win})
  vim.api.nvim_set_option_value("relativenumber", false, {win = self.main_win})
  if self.float then
    utils.register_to_close_on_leave(self.main_win)
  end
  self:make_waybar()
end

-- need to rename it to winbar (oops)
function Dapi:make_waybar()
  local indent = "    "
  local waybar_comp = {self.scopes, self.terminal, self.repl}
  local winbar = {}
  for _, comp in ipairs(waybar_comp) do
    local text = comp.name
    if comp == self.active then
      text = utils.status_line_apply_hl(text, "Exception")
    end
    table.insert(winbar, text)
  end
  vim.wo[self.main_win].winbar = table.concat(winbar, indent)
end

function Dapi:close()
  if utils.is_win_valid(self.main_win) then
    vim.api.nvim_win_close(self.main_win, true)
  end
end

function Dapi:rotate()
  if not utils.is_win_valid(self.main_win) then
    return
  end
  local cur_direction = self.direction
  self:close()
  local directions = { "below", "left", "above", "right" }
  for i, direction in ipairs(directions) do
    if direction == cur_direction then
      -- damn lua...
      local next = directions[i % #directions + 1]
      self:open({ direction = next })
    end
  end
end

function Dapi:toggle_layout()
  if not utils.is_win_valid(self.main_win) then
    return
  end
  self:close()
  self:open({ float = not self.float })
end

function Dapi:focus_scopes()
  self.active = self.scopes
  vim.api.nvim_win_set_buf(self.main_win, self.scopes.buf)
  self:make_waybar()
end

function Dapi:focus_repl()
  self.active = self.repl
  vim.api.nvim_win_set_buf(self.main_win, self.repl.buf)
  self:make_waybar()
end

function Dapi:focus_terminal()
  self.active = self.terminal
  vim.api.nvim_win_set_buf(self.main_win, self.terminal.buf)
  self:make_waybar()
end

return M
