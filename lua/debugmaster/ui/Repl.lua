local utils = require("debugmaster.utils")
local repl = require 'dap.repl'
local dap = require("dap")

---@class dm.ui.Repl: dm.ui.Sidepanel.IComponent
local Repl = {}

function Repl.new()
  ---@class dm.ui.Repl
  local self = setmetatable({}, {__index = Repl})

  local repl_buf, repl_win = repl.open()
  vim.api.nvim_win_close(repl_win, true)
  self.name = "[R]epl"
  self.buf = repl_buf
  -- https://github.com/mfussenegger/nvim-dap/issues/786
  vim.keymap.set("i", "<C-w>", "<C-S-w>", {buffer = self.buf})
  vim.keymap.set("n", "<Tab>", "<CR>", {buffer = self.buf, remap = true})

  dap.listeners.after.initialize["repl-hl"] = function(session, err, response, args, seq)
    pcall(vim.treesitter.stop, self.buf)
    pcall(vim.treesitter.start, self.buf, vim.o.filetype)
  end

  return self
end

return Repl
