local tree = require("debugmaster.lib.tree")
local dap = require("dap")

local threads = {}

---@param node dm.ThreadsTreeNode
function threads.render_node(node)
  if node.kind == "thread" then
    local thread_name = string.format("[%s] Thread name: %s", tostring(node.id), node.name)
    return { { thread_name } }
  elseif node.kind == "frame" then
    return { { "   " }, {node.name} }
  end
end

function threads.find_current()
end

threads.comp = (function()
  ---@alias dm.ThreadsRootNode {kind: "root", children: dm.ThreadsNode}

  ---@class dm.ThreadsNode: dap.Thread
  ---@field kind "thread"
  ---@field collapsed? boolean
  ---@field children dm.FramesNode[]

  ---@class dm.FramesNode: dap.StackFrame
  ---@field kind "frame"

  ---@alias dm.ThreadsTreeNode dm.ThreadsNode | dm.FramesNode | dm.ThreadsRootNode


  local tr = tree.new {
    root = {},
    renderer = threads.render_node,
  }

  dap.listeners.after.stackTrace["threads_widget"] = function()
    local s = dap.session()
    if not s then
      return
    end
    tr.root = { children = {} }
    for _, thread in pairs(s.threads --[=[@as dm.ThreadsNode[]]=]) do
      thread.kind = "thread"
      thread.children = {}
      for _, frame in ipairs(thread.frames --[=[@as dm.FramesNode[]]=]) do
        frame.kind = "frame"
        table.insert(thread.children, frame)
      end
      table.insert(tr.root.children, thread)
    end
    tr:refresh()
  end

  return {
    name = "[T]hreads",
    buf = tr.buf
  }
end)()

return threads
