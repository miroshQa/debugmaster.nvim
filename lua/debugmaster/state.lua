local dap = require("dap")
local config = require("debugmaster.config")

---@class debugmaster.State
local M = {}

local term_buf = nil

dap.defaults.fallback.terminal_win_cmd = function(cfg)
  term_buf = vim.api.nvim_create_buf(false, false)
  return term_buf, nil
end

M.sidepanel = require("debugmaster.ui.Sidepanel").new()
M.terminal = require("debugmaster.ui.components.Terminal").new({})
M.repl = require("debugmaster.ui.components.Repl").new()
M.scopes = require("debugmaster.ui.components.Scopes").new()
M.help = require("debugmaster.ui.components.Help").new(config.groups)

M.sidepanel:add_component(M.scopes)
M.sidepanel:add_component(M.terminal)
M.sidepanel:add_component(M.repl)
M.sidepanel:add_component(M.help)

M.sidepanel:set_active(M.scopes)

dap.listeners.before.launch.dapui_config = function()
  M.sidepanel:open()
  term_buf = nil
end

dap.listeners.before.attach.dapui_config = function()
  M.sidepanel:open()
  term_buf = nil
end

dap.listeners.before.event_terminated.dapui_config = function()
  M.sidepanel:close()
  print("dap terminated")
end

dap.listeners.before.event_exited.dapui_config = function()
  M.sidepanel:close()
end

return M
