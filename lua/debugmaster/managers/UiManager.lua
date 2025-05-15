local UiManager = {}

UiManager.sidepanel = require("debugmaster.components.generic.multiwin").new()
UiManager.breakpoints = require("debugmaster.components.breakpoints").comp
-- UiManager.sessions = require("debugmaster.components.sessions").comp
UiManager.terminal = require("debugmaster.components.terminal").comp
UiManager.scopes = require("debugmaster.components.scopes").comp
UiManager.repl = require("debugmaster.components.repl").comp
UiManager.help = require("debugmaster.components.help").comp

UiManager.sidepanel:add_component(UiManager.scopes)
UiManager.sidepanel:add_component(UiManager.terminal)
UiManager.sidepanel:add_component(UiManager.help)
UiManager.sidepanel:add_component(UiManager.repl)

UiManager.sidepanel:set_active(UiManager.scopes)


-- Initialize UI on firts requrie

return UiManager
