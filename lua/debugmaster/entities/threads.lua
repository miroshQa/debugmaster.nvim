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

threads.renderer = tree.dispatcher.renderer.new {
  ---@param node dm.ThreadsNode
  thread = function(node)
    local icon = node.collapsed and "  " or "  "
    local thread_name = string.format("[%s] Thread name: %s", tostring(node.id), node.name)
    return {
      { { icon }, { thread_name } },
    }
  end,
  ---@param node dm.FrameNode
  frame = function(node)
    local icon = SessionManager.is_current_frame(node) and "  " or ""
    local path = (node.source or {}).path or "unknown"
    return {
      { { "  " }, { icon .. node.name }, { string.format(" (path: %s)", path) } },
    }
  end
}

function threads.find_current()
end

---@type table<string, dm.TreeNodeAction>
threads.actions = {
  ["<CR>"] = tree.dispatcher.action.new {
    ---@param cur dm.ThreadsNode
    thread = function(cur, v)
      cur.collapsed = not cur.collapsed
      v:refresh()
    end,
    ---@param cur dm.FrameNode
    frame = function(cur, _)
      SessionManager.set_current_frame(cur)
    end,
  },
  ["K"] = tree.dispatcher.action.new {
    thread = function(cur, _)
      local b = vim.api.nvim_create_buf(false, true)
      vim.bo[b].filetype = "lua"
      vim.api.nvim_buf_set_lines(b, 0, -1, false, vim.split(vim.inspect(cur), "\n"))
      view.close_on_q(view.new_float_anchored(b))
    end,
    frame = "thread"
  }
}

return threads
