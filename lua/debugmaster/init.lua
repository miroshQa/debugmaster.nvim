local M = {}

local dap = require("dap")
local config = require("debugmaster.config")
local Dapi = require("debugmaster.Dapi")
local debugmode = require("debugmaster.debugmode")

M.dapi = nil
local term_buf = nil

dap.defaults.fallback.terminal_win_cmd = function(cfg)
  term_buf = vim.api.nvim_create_buf(false, false)
  return term_buf, nil
end

vim.keymap.set("n", "<leader>du", function()
  if M.dapi then
    M.dapi:toggle()
  end
end)

-- Alternatives:
-- 1. Enter, Tab, m
vim.keymap.set("n", "<Tab>", function()
  debugmode.toggle()
end)

dap.listeners.before.launch.dapui_config = function()
  M.dapi = Dapi.new(term_buf)
  M.dapi:open()
end

dap.listeners.before.event_terminated.dapui_config = function()
  M.dapi:close()
end

return M
