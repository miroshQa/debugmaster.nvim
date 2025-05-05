local M = {}
local keymaps = require("debugmaster.debug.keymaps")

M.cfg = require("debugmaster.cfg")

-- maybe want to lazyload it in the future. not critical right now anyway
M.plugins = require("debugmaster.plugins")
local plugins_enabled = false

M.mode = {
  toggle = function()
    if not plugins_enabled then
      for _, plugin in pairs(M.plugins) do
        if plugin.enabled == nil or plugin.enabled then
          plugin.activate()
        end
      end
      plugins_enabled = true
    end
    require("debugmaster.state")
    require("debugmaster.debug.mode").toggle()
  end
}

M.keys = {
  get = keymaps.get,
  add = keymaps.add
}

return M
