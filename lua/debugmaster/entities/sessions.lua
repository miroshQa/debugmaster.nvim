local dap = require("dap")
local tree = require("debugmaster.lib.tree")

local sessions = {}


---@alias dm.SessionrootNode {handler: dm.TreeNodeEventHandler, children: dm.SessionNode[]}
---@alias dm.SessionNode {handler: dm.SessionNodeEventHandler, session: dap.Session}
---@alias dm.SessionTreeNode dm.SessionNode | dm.SessionrootNode

sessions.root_handler = tree.dispatcher.new {
  render = function(event)
    event.out.lines = {
      { { "SESSIONS:", "WarningMsg" } },
    }
  end,
  keymaps = {},
}

---@alias dm.SessionNodeEventHandler fun(event: dm.SessionRenderEvent)
---@type dm.SessionNodeEventHandler
sessions.session_handler = tree.dispatcher.new {
  ---@class dm.SessionRenderEvent: dm.TreeNodeRenderEvent
  ---@field cur dm.SessionNode
  ---@param event dm.SessionRenderEvent
  render = function(event)
    local node = event.cur
    event.out.lines = {
      { { string.format("%s. ", node.id) }, { node.config.name } },
    }
  end,
  ---@class dm.SessionKeymapEvent: dm.TreeNodeKeymapEvent
  ---@field cur dm.SessionNode
  ---@type table<string, fun(event: dm.SessionKeymapEvent)>
  keymaps = {
    ["<CR>"] = function(event)
      print("session switching isn't implemented yet")
    end
  }
}

return sessions
