local tree = require("debugmaster.lib.tree")
local SessionManager = require("debugmaster.managers.SessionsManager")
local view = require("debugmaster.lib.view")
local dap = require("dap")

local threads = {}


---@alias dm.ThreadsRootNode {kind: "root", children: dm.ThreadsNode}

---@class dm.ThreadsNode: dap.Thread
---@field kind "thread"
---@field collapsed? boolean
---@field children dm.FrameNode[]

---@class dm.FrameNode: dap.StackFrame
---@field kind "frame"

---@alias dm.ThreadsTreeNode dm.ThreadsNode | dm.FrameNode | dm.ThreadsRootNode

local count = 0
threads.thread_handler = tree.dispatcher.new {
  render = function(event)
    print("thread renderred: " .. count)
    count = count + 1
    local node = event.cur
    local icon = node.collapsed and "  " or "  "
    local thread_name = string.format("[%s] Thread name: %s", tostring(node.id), node.name)
    event.out.lines = {
      { { icon }, { thread_name } },
    }
  end,
  keymaps = {
    ["<CR>"] = function(event)
      local cur = event.cur
      cur.collapsed = not cur.collapsed
      event.view:refresh()
    end
  }
}

threads.frame_handler = tree.dispatcher.new {
  render = function(event)
    local node = event.cur
    local icon = SessionManager.is_current_frame(node) and "  " or ""
    local path = (node.source or {}).path or "unknown"
    event.out.lines = {
      { { "  " }, { icon .. node.name }, { string.format(" (path: %s)", path) } },
    }
  end,
  keymaps = {
    ["<CR>"] = function(event)
      SessionManager.set_current_frame(event.cur)
    end
  }
}

return threads
