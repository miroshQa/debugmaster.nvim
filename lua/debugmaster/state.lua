local dap = require("dap")
local groups = require("debugmaster.debug.keymaps").groups

---@class dm.State
local M = {}

M.sidepanel = require("debugmaster.ui.Sidepanel").new()
M.terminal = require("debugmaster.ui.Terminal").new()
M.repl = require("debugmaster.ui.Repl").new()
M.scopes = require("debugmaster.ui.Scopes").new()
M.help = require("debugmaster.ui.Help").new(groups)
M.breakpoints = require("debugmaster.ui.Breakpoints").new()

M.sidepanel:add_component(M.scopes)
M.sidepanel:add_component(M.terminal)
M.sidepanel:add_component(M.repl)
M.sidepanel:add_component(M.breakpoints)
M.sidepanel:add_component(M.help)

M.sidepanel:set_active(M.scopes)

dap.listeners.before.launch["dm-autoopen"] = function()
  M.sidepanel:open()
end

dap.listeners.before.attach["dm-autoopen"] = function()
  M.sidepanel:open()
end

dap.listeners.before.event_terminated["dm-autoclose"] = function()
  M.sidepanel:close()
  print("dap terminated")
end

dap.listeners.before.event_exited["dm-autoclose"] = function()
  M.sidepanel:close()
  print("dap exited")
end

return M
