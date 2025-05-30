local tree = require("debugmaster.lib.tree")

local watches = {}


watches.handler = tree.dispatcher.new {
  render = function(node, event)
  end,
  keymaps = { "<CR>" },
}

return watches
