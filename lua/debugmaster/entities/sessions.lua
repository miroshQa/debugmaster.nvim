local dap = require("dap")
local tree = require("debugmaster.lib.tree")
local SessionsManager = require("debugmaster.managers.SessionsManager")

local sessions = {}


---@alias dm.SessionrootNode {handler: dm.TreeNodeEventHandler, children: dm.SessionNode[]}

---@class dm.SessionNode: dap.Session
---@field handler dm.SessionNodeEventHandler

---@alias dm.SessionTreeNode dm.SessionNode | dm.SessionrootNode

sessions.root_handler = tree.dispatcher.new {
  render = function(_, event)
    event.out.lines = {
      { { "SESSIONS:", "WarningMsg" } },
    }
  end,
  keymaps = {},
}

---@alias dm.SessionNodeEventHandler dm.SessionNodeEventHandler
---@type dm.SessionNodeEventHandler
sessions.session_handler = tree.dispatcher.new {
  ---@param node dm.SessionNode
  render = function(node, event)
    local cur_session = dap.session()
    local icon = (cur_session or {}).id == node.id and "->" or ""
    event.out.lines = {
      { { string.format("%s %s. %s ", icon, node.id, node.config.name) } },
    }
  end,
  ---@type table<string, fun(node: dm.SessionNode, event: dm.TreeNodeKeymapEvent)>
  keymaps = {
    ["<CR>"] = function(node, event)
      dap.set_session(node)
      SessionsManager.set_active(node)
      event.view:refresh()
    end
  }
}

function sessions.construct()
  local children = {}
  for _, s in pairs(dap.sessions() --[=[@as dm.SessionNode[]]=]) do
    s.handler = sessions.session_handler
    table.insert(children, s)
  end
  return children
end

return sessions
