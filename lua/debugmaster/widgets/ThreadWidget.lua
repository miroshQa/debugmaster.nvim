---@module "dap"

local async = require("debugmaster.lib.async")
local SessionManager = require("debugmaster.managers.SessionsManager")
local FrameWidget = require("debugmaster.widgets.FrameWidget")
local common = require("debugmaster.widgets.common")

---@class dm.ThreadWidget: dap.Thread, dm.Widget
---@field session dap.Session
---@field children dm.FrameWidget[]
---@field child_by_name table<string, dm.FrameWidget>
local ThreadWidget = {}
---@private
ThreadWidget.__index = ThreadWidget

---@type dm.WidgetRenderer
function ThreadWidget:render(out)
  local icon = self.collapsed and "  " or "  "
  local thread_name = string.format("[%s] Thread name: %s", tostring(self.id), self.name)
  out.lines = {
    { { icon }, { thread_name } },
  }
end

---@param session dap.Session
---@param thread dap.Thread
---@return dm.ThreadWidget
function ThreadWidget.new(session, thread)
  local self = setmetatable(thread, ThreadWidget)
  self.session = session
  self.collapsed = true
  ---@diagnostic disable-next-line: return-type-mismatch
  return self
end

---@param cb fun() called on done
function ThreadWidget:load(cb)
  if self.children then
    return cb()
  end
  self.child_by_name = {}
  self.children = {}
  ---@param result dap.StackTraceResponse
  self.session:request("stackTrace", { threadId = self.id }, function(err, result)
    for _, frame in ipairs(result.stackFrames) do
      local widget = FrameWidget.new(self.session, frame)
      table.insert(self.children, widget)
      self.child_by_name[frame.name] = widget
    end
    cb()
  end)
end

---@type table<string, fun(node: dm.ThreadWidget, canvas: dm.Canvas)>
ThreadWidget.keymaps = {
  ["<CR>"] = function(self, canvas)
    self:load(function()
      self.collapsed = not self.collapsed
      canvas:refresh(self)
    end)
  end
}

return ThreadWidget
