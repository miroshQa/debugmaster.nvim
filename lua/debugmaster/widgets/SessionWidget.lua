local dap = require("dap")
local ThreadWidget = require("debugmaster.widgets.ThreadWidget")
local common = require("debugmaster.widgets.common")

---@class dm.SessionWidget: dm.Widget
---@field children dm.ThreadWidget[]
---@field child_by_name table<string, dm.ThreadWidget>
---@field collapsed boolean
---@field session dap.Session
local SessionWidget = {}
---@private
SessionWidget.__index = SessionWidget

function SessionWidget:render(out)
  print("session render")
  local s = dap.sessions()[self.session.id]
  local cur_session = assert(dap.session())
  local icon = cur_session.id == self.session.id and "->" or ""
  out.lines = {
    { { string.format("%s %s. %s ", icon, self.session.id, s.config.name) } },
  }
end

---@param session dap.Session
function SessionWidget.new(session)
  return setmetatable({
    session = session,
    collapsed = true,
  }, SessionWidget)
end

function SessionWidget:load(cb)
  self.children = {}
  self.child_by_name = {}
  self.session:request("threads", nil, function(err, result)
    assert(not err)
    for _, thread in pairs(result.threads) do
      local widget = ThreadWidget.new(self.session, thread)
      self.child_by_name[thread.name] = widget
      table.insert(self.children, widget)
    end
    cb()
  end)
end

function SessionWidget:sync(from, cb)
  common.sync(self, from, cb)
end

---@type table<string, fun(node: dm.SessionWidget, view: dm.TreeView)>
SessionWidget.keymaps = {
  ["<CR>"] = function(self, view)
    self:load(function()
      self.collapsed = not self.collapsed
      local SessionsManager = require("debugmaster.managers.SessionsManager")
      SessionsManager.set_active(self.session)
      view:refresh()
    end)
  end
}


return SessionWidget
