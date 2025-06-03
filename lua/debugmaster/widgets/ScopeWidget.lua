---@module "dap"

local async = require("debugmaster.lib.async")
local VariableWidget = require("debugmaster.widgets.VariableWidget")
local common = require("debugmaster.widgets.common")

---@class dm.ScopeWidget: dap.Scope, dm.Widget
---@field session dap.Session
---@field child_by_name table<string, dm.VariableWidget> in this case id is a string (name)
---@field children dm.VariableWidget[]
local ScopeWidget = {}
---@private
ScopeWidget.__index = ScopeWidget

---@param session dap.Session
---@param scope dap.Scope
---@return dm.ScopeWidget
function ScopeWidget.new(session, scope)
  local self = setmetatable(scope, ScopeWidget)
  self.session = session
  self.collapsed = true
  ---@diagnostic disable-next-line: return-type-mismatch
  return self
end


---@type dm.WidgetRenderer
function ScopeWidget:render(out, parent, depth)
  local icon = self.collapsed and " " or " "
  icon = self.variablesReference == 0 and "" or icon
  local indent = string.rep(" ", depth)
  out.lines = {
    { { indent }, { icon }, { self.name } },
  }
end

---@param cb fun() called on done
function ScopeWidget:load(cb)
  VariableWidget.load(self, cb)
end

---@type table<string, fun(self: dm.ScopeWidget, view: dm.TreeView)>
ScopeWidget.keymaps = {
  ["<CR>"] = function(self, view)
    self:load(function()
      self.collapsed = not self.collapsed
      view:refresh(self)
    end)
  end,
  ["K"] = common.inspect
}

return ScopeWidget
