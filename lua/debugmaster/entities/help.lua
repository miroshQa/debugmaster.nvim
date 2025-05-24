local tree = require("debugmaster.lib.tree")
local help = {}

---@class dm.HelpNodeRoot: dm.TreeNode
---@field groups dm.MappingsGroup[]

help.help_handler = tree.dispatcher.new {
  ---@param node dm.HelpNodeRoot
  render = function(node, event)
    local lines = {}
    for _, group in ipairs(node.groups) do
      table.insert(lines, { { group.name, group.hlgroup } })
      for _, spec in ipairs(group.mappings) do
        if spec.desc then
          local key = spec.key
          local indent = string.rep(" ", 10 - #key)
          table.insert(lines, { { string.format("%s %s  %s", key, indent, spec.desc) } })
        end
      end
      table.insert(lines, { { "" } })
    end
    event.out.lines = lines
  end,
  keymaps = {}
}

return help
