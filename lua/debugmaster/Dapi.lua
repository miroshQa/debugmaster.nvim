local dap = require("dap")
local utils = require("debugmaster.utils")
local widgets = require('dap.ui.widgets')
local repl = require 'dap.repl'

local M = {}

--- Debug adapter interface
---@class debugmaster.Dapi
local Dapi = {}

function M.new(term_buf)
  ---@class debugmaster.Dapi
  local self = setmetatable({}, { __index = Dapi })
  self.hints_ns = vim.api.nvim_create_namespace("dapi-hints")
  self.main_win = nil
  local scopes = widgets.sidebar(widgets.scopes)

  local repl_buf, repl_win = repl.open()
  self.repl_buf = repl_buf
  vim.api.nvim_win_close(repl_win, true)

  local scopes_buf, scopes_win = scopes.open()
  self.scopes_buf = scopes_buf
  vim.api.nvim_win_close(scopes_win, true)
  vim.api.nvim_buf_set_keymap(scopes_buf, "n", "q", "<cmd>q<CR>", {})

  self.terminal_buf = term_buf


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
---@field direction "left" | "right" | "above" | "below" | nil Opens right by default if nil
---@field float boolean? If float specified then it creates float window and ignore direction

---@param opts debugmaster.Dapi.OpenOptions?
function Dapi:open(opts)
  if not self.scopes_buf then
    return print("Can't open dapi. Debug session is not active")
  end

  if utils.is_win_valid(self.main_win) then
    return
  end

  opts = opts or {}
  local direction = opts.direction or self.direction or "right"
  ---@type vim.api.keyset.win_config
  local cfg = {}
  local enter = false
  if opts.float or self.float then
    cfg = utils.make_center_float_win_cfg()
    self.float = true
    enter = true
  else
    cfg.split = direction
  end

  --  it saves us if we try open it in a float window
  local ok, res = pcall(vim.api.nvim_open_win, self.scopes_buf, enter, cfg)
  if not ok then
    return
  end

  self.main_win = res
  self.direction = direction

  if self.float then
    utils.register_to_close_on_leave(self.main_win)
  end
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

function Dapi:last_pane_to_float()
  if not utils.is_win_valid(self.main_win) then
    return
  end
  self:close()
  self:open({ float = true })
end

function Dapi:focus_scopes()
  vim.api.nvim_win_set_buf(self.main_win, self.scopes_buf)
end

function Dapi:focus_repl()
  vim.api.nvim_win_set_buf(self.main_win, self.repl_buf)
end

function Dapi:focus_terminal()
  vim.api.nvim_win_set_buf(self.main_win, self.terminal_buf)
end

return M
