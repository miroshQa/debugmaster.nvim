---@class dm.HelpWidget: dm.Widget
---@field groups dm.MappingsGroup[]
local HelpWidget = {}
---@private
HelpWidget.__index = HelpWidget

---@type dm.WidgetRenderer
function HelpWidget:render(out)
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

function HelpWidget.new(groups)
  return setmetatable({ groups = groups }, HelpWidget)
end

HelpWidget.keymaps = {}

return HelpWidget
