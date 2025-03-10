local M = {}

local dap = require("dap")
local config = require("debugmaster.config")
local Dapi = require("debugmaster.Dapi")
local debugmode = require("debugmaster.debugmode")

local dapi = nil
local term_buf = nil

dap.defaults.fallback.terminal_win_cmd = function(cfg)
  term_buf = vim.api.nvim_create_buf(false, false)
  return term_buf, nil
end

vim.keymap.set("n", "<leader>du", function()
  if dapi then
    dapi:toggle()
  end
end)

-- Alternatives:
-- 1. Enter
vim.keymap.set("n", "m", function()
  debugmode.activate()
end)

dap.listeners.before.launch.dapui_config = function()
  dapi = Dapi.new(term_buf)
  dapi:open()
end

dap.listeners.before.event_terminated.dapui_config = function()
  dapi:close()
end

return M
