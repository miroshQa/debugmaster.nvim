---@class dm.State
local M = {}

M.sidepanel = require("debugmaster.ui.Sidepanel").new()
M.terminal = require("debugmaster.ui.Terminal").new()
M.repl = require("debugmaster.ui.Repl").new()
M.scopes = require("debugmaster.ui.Scopes").new()
M.help = require("debugmaster.ui.Help").new(require("debugmaster.managers.DmManager").get_groups())
M.breakpoints = require("debugmaster.ui.Breakpoints").new()

M.sidepanel:add_component(M.scopes)
M.sidepanel:add_component(M.repl)
M.sidepanel:add_component(M.terminal)
M.sidepanel:add_component(M.help)

M.sidepanel:set_active(M.scopes)

return M
