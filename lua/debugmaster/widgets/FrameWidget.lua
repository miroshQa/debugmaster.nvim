---@module "dap"

local async = require("debugmaster.lib.async")
local SessionManager = require("debugmaster.managers.SessionsManager")
local ScopeWidget = require("debugmaster.widgets.ScopeWidget")
local common = require("debugmaster.widgets.common")

---@class dm.FrameWidget: dap.StackFrame, dm.Widget
---@field session dap.Session
---@field child_by_name table<string, dm.ScopeWidget>?
---@field children dm.ScopeWidget[]? nil means not loaded
local FrameWidget = {}
---@private
FrameWidget.__index = FrameWidget

---@param session dap.Session
---@param frame dap.StackFrame
---@return dm.FrameWidget
function FrameWidget.new(session, frame)
  local self = setmetatable(frame, FrameWidget)
  self.session = session
  self.collapsed = true
  ---@diagnostic disable-next-line: return-type-mismatch
  return self
end


---@type dm.WidgetRenderer
function FrameWidget:render(out)
  local icon = SessionManager.is_current_frame(self.id) and "  " or ""
  local path = (self.source or {}).path
  path = path and vim.fn.fnamemodify(path, ":.") or "unknown"
  out.lines = {
    { { "  " }, { icon .. self.name }, { string.format(" (%s)", path), "Comment" } },
  }
end

function FrameWidget:load(cb)
  if self.children then
    return cb()
  end
  self.children = {}
  self.child_by_name = {}
  ---@param err any
  ---@param result dap.ScopesResponse
  self.session:request("scopes", { frameId = self.id }, function(err, result)
    assert(not err)
    for _, scope in ipairs(result.scopes) do
      local widget = ScopeWidget.new(self.session, scope)
      self.child_by_name[scope.name] = widget
      table.insert(self.children, widget)
    end
    cb()
  end)
end

---@type table<string, fun(self: dm.FrameWidget, canvas: dm.Canvas)>
FrameWidget.keymaps = {
  ["<CR>"] = function(self, canvas)
    self:load(function()
      self.collapsed = not self.collapsed
      SessionManager.set_current_frame(self.id)
      canvas:refresh()
    end)
  end,
}

return FrameWidget
