local dap = require("dap")

local sessions = {}

---@class dm.Session: dm.TreeNode
---@field id number
---@field config dap.Configuration
local Session = {}
---@private
Session.__index = Session


function Session:render(out)
  local cur_session = dap.session()
  local icon = (cur_session or {}).id == self.id and "->" or ""
  out.lines = {
    { { string.format("%s %s. %s ", icon, self.id, self.config.name) } },
  }
end

---@type table<string, fun(node: dm.Session, view: dm.TreeView)>
Session.keymaps = {
  ["<CR>"] = function(self, view)
    local SessionsManager = require("debugmaster.managers.SessionsManager")
    SessionsManager.set_active(dap.sessions()[self.id])
    view:refresh()
  end
}

sessions.Session = Session

return sessions
