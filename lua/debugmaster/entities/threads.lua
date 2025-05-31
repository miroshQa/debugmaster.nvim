local dap = require("dap")

local threads = {}

---@class dm.Thread: dap.Thread, dm.TreeNode
local Thread = {}
---@private
Thread.__index = Thread

---@type dm.TreeNodeRenderer
function Thread:render(out)
  local icon = self.collapsed and "  " or "  "
  local thread_name = string.format("[%s] Thread name: %s", tostring(self.id), self.name)
  out.lines = {
    { { icon }, { thread_name } },
  }
end

---@type table<string, fun(node: dm.Thread, view: dm.TreeView)>
Thread.keymaps = {
  ["<CR>"] = function(node, view)
    node.collapsed = not node.collapsed
    view:refresh(node)
  end
}

---@class dm.Frame: dap.StackFrame
local Frame = {}
---@private
Frame.__index = Frame

function Frame:render(out)
  local SessionManager = require("debugmaster.managers.SessionsManager")
  local icon = SessionManager.is_current_frame(self) and "  " or ""
  local path = (self.source or {}).path
  path = path and vim.fn.fnamemodify(path, ":.") or "unknown"
  out.lines = {
    { { "  " }, { icon .. self.name }, { string.format(" (%s)", path), "Comment" } },
  }
end

---@type table<string, fun(node: dm.Frame, view: dm.TreeView)>
Frame.keymaps = {
  ["<CR>"] = function(node, view)
    local SessionManager = require("debugmaster.managers.SessionsManager")
    SessionManager.set_current_frame(node)
    view:refresh()
  end
}

threads.Frame = Frame
threads.Thread = Thread

return threads
