local utils = require("debugmaster.utils")
local repl = require 'dap.repl'


local M = {}

---@class debugmaster.ui.Repl: debugmaster.ui.Sidepanel.IComponent
local Repl = {}

function M.new()
  ---@class debugmaster.ui.Repl
  local self = setmetatable({}, {__index = Repl})

  local repl_buf, repl_win = repl.open()
  vim.api.nvim_win_close(repl_win, true)
  self.name = "[R]epl"
  self.buf = repl_buf
  return self
end

return M
