local M = {}
local keymaps = require("debugmaster.debug.keymaps")

M.cfg = require("debugmaster.cfg")

M.mode = {
  toggle = function()
    require("debugmaster.state")
    require("debugmaster.plugins")
    require("debugmaster.debug.mode").toggle()
  end
}

M.keys = {
  get = keymaps.get,
  add = keymaps.add
}

return M
