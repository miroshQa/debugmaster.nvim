local M = {}
require("debugmaster.lib.utils")

M.cfg = require("debugmaster.cfg")

-- maybe want to lazyload it in the future. not critical right now anyway
M.plugins = require("debugmaster.plugins").plugins

M.mode = {
  toggle = function()
    -- TODO: Move this whole logic except mode toggle to deferred_init.lua or something
    require("debugmaster.managers.UiManager")
    require("debugmaster.managers.SessionsManager")
    require("debugmaster.plugins").init()
    require("debugmaster.managers.DmManager").dmode:toggle()
  end,
  disable = function()
    require("debugmaster.managers.DmManager").dmode:disable()
  end
}

M.keys = {
  ---Give the reference to the key entry so you can remap it to something else
  ---Throws an error if the key doesn't exist
  ---@return dm.MappingSpec
  get = function(key)
    local groups = require("debugmaster.managers.DmManager").get_groups()
    for _, group in pairs(groups) do
      for _, mapping in ipairs(group.mappings) do
        if mapping.key == key then
          return mapping
        end
      end
    end
    error("Key doesn't exist")
  end,
  --- Add new user mapping to the last group
  ---@param mapping dm.MappingSpec
  add = function(mapping)
    local groups = require("debugmaster.managers.DmManager").get_groups()
    table.insert(groups[#groups].mappings, mapping)
  end
}

return M
