local M = {}
local keymaps = require("debugmaster.debug.keymaps")

M.cfg = require("debugmaster.cfg")

-- maybe want to lazyload it in the future. not critical right now anyway
M.plugins = require("debugmaster.plugins").plugins

M.mode = {
  toggle = function()
    require("debugmaster.plugins").init()
    require("debugmaster.state")
    require("debugmaster.debug.mode").toggle()
  end
}

M.keys = {
  get = keymaps.get,
  add = keymaps.add
}

return M
