local tree = require("debugmaster.lib.tree")
local SessionManager = require("debugmaster.managers.SessionsManager")
local dap = require("dap")

local threads = {}


---@alias dm.ThreadsRootNode {kind: "root", children: dm.ThreadsNode}

---@class dm.ThreadsNode: dap.Thread, dm.TreeNode
---@field collapsed? boolean
---@field children dm.FrameNode[]

---@class dm.FrameNode: dap.StackFrame, dm.TreeNode

---@alias dm.ThreadsTreeNode dm.ThreadsNode | dm.FrameNode | dm.ThreadsRootNode

threads.root_handler = tree.dispatcher.new {
  render = function(node, event)
    event.out.lines = {
      { { "THREADS", "WarningMsg" } }
    }
  end,
  keymaps = {},
}

threads.thread_handler = tree.dispatcher.new {
  ---@param node dm.ThreadsNode
  render = function(node, event)
    local icon = node.collapsed and "  " or "  "
    local thread_name = string.format("[%s] Thread name: %s", tostring(node.id), node.name)
    event.out.lines = {
      { { icon }, { thread_name } },
    }
  end,
  ---@type table<string, fun(node: dm.ThreadsNode, event: dm.TreeNodeKeymapEvent)>
  keymaps = {
    ["<CR>"] = function(node, event)
      node.collapsed = not node.collapsed
      event.view:refresh(node)
    end
  }
}

threads.frame_handler = tree.dispatcher.new {
  ---@param node dm.FrameNode
  render = function(node, event)
    local icon = SessionManager.is_current_frame(node) and "  " or ""
    local path = (node.source or {}).path
    path = path and vim.fn.fnamemodify(path, ":.") or "unknown"
    event.out.lines = {
      { { "  " }, { icon .. node.name }, { string.format(" (%s)", path), "Comment" } },
    }
  end,
  ---@type table<string, fun(node: dm.FrameNode, event: dm.TreeNodeKeymapEvent)>
  keymaps = {
    ["<CR>"] = function(node, event)
      SessionManager.set_current_frame(node)
      event.view:refresh()
    end
  }
}

return threads
