local dap = require("dap")
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

  self.terminal_buf = term_buf
  return self
end

function Dapi:toggle()
  if not self.main_win or not vim.api.nvim_win_is_valid(self.main_win) then
    self:open()
  else
    self:close()
  end
end

function Dapi:open()
  if not self.scopes_buf then
    return print("Can't toggle dapi. Debug session is not active")
  end
  --  it saves us if we try open it in a float window
  local ok, res = pcall(vim.api.nvim_open_win, self.scopes_buf, false, {
    split = "right",
  })
  print(ok, res)
  if ok then
    self.main_win = res
  end
end

function Dapi:close()
  if vim.api.nvim_win_is_valid(self.main_win) then
    vim.api.nvim_win_close(self.main_win, true)
    self.main_win = nil
  end
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
