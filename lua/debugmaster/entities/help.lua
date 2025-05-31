local help = {}


---@class dm.Help: dm.TreeNode
---@field groups dm.MappingsGroup[]
local Help = {}
---@private
Help.__index = Help

---@type dm.TreeNodeRenderer
function Help:render(out)
  local lines = {}
  for _, group in ipairs(self.groups) do
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
  out.lines = lines
end

Help.keymaps = {}

help.Help = Help

return help
