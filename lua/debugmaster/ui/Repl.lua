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
  -- https://github.com/mfussenegger/nvim-dap/issues/786
  vim.keymap.set("i", "<C-w>", "<C-S-w>", {buffer = self.buf})
  vim.keymap.set("n", "<Tab>", "<CR>", {buffer = self.buf, remap = true})
  return self
end

return M
