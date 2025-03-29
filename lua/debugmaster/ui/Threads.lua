local dap = require("dap")
local Tree = require("debugmaster.ui.Tree")

--- It is either frame, either thread, or root node otherwise
---@class ThreadsNode: dm.NodeTrait
---@field thread? dap.Thread
---@field frame? dap.StackFrame
local ThreadsNode = {}

function ThreadsNode.new(thread, frame)
  ---@class ThreadsNode
  local self = setmetatable({}, { __index = ThreadsNode })
  self.id = "dummy"
  if thread or frame then
    self.id = frame and ("frame:" .. frame.id) or ("thread:" .. thread.id)
  end
  self.thread = thread
  self.frame = frame
  return self
end

function ThreadsNode:get_children_iter()
  local session = assert(require("dap").session())
  -- rust enums kind off
  if not self.thread and not self.frame then
    return vim.iter(session.threads):map(function(t) return ThreadsNode.new(t, nil) end)
  elseif self.thread then
    return vim.iter(self.thread.frames):map(function(f) return ThreadsNode.new(nil, f) end)
  elseif self.frame then
    return function() end
  end
end

function ThreadsNode:get_repr(depth)
  local session = assert(require("dap").session())
  if not self.thread and not self.frame then
    return { { "Debug Threads", "Title" } }
  elseif self.thread then
    local icon = " "
    local hl = "DapThread"
    if self.thread.stopped then
      icon = "⏸ "
      hl = "DapStoppedThread"
    end
    return {
      { "  " .. self.thread.name .. icon, hl }
    }
  elseif self.frame then
    local icon = " "
    local hl = "DapFrame"
    if session.current_frame.id == self.frame.id then
      icon = "  "
      hl = "DapCurrentFrame"
    end
    return {
      { "    " .. self.frame.name .. icon, hl }
    }
  end
end

function ThreadsNode:is_expanded()
  return true
end

---@class dm.ui.Threads: dm.ui.Sidepanel.IComponent
local Threads = {}

function Threads.new()
  ---@class dm.ui.Threads
  local self = setmetatable({}, { __index = Threads })
  self.name = "[T]hreads"
  self._tree = Tree.new_with_buf(ThreadsNode.new(nil, nil))
  self.buf = self._tree.buf

  dap.listeners.after.stackTrace["debugmaster"] = function(session)
    self._tree:render()
  end


  vim.api.nvim_buf_set_keymap(self.buf, "n", "<CR>", "", {
    callback = function()
      local line = vim.api.nvim_win_get_cursor(0)[1] - 1
      local node = self._tree:node_by_line(line)
      if node and node.frame then
        require("dap").session():_frame_set(node.frame)
      end
    end
  })
  return self
end

vim.api.nvim_set_hl(0, "DapStoppedThread", { fg = "#FF0000" })
vim.api.nvim_set_hl(0, "DapCurrentFrame", { bold = true, fg = "#569CD6" })
vim.api.nvim_set_hl(0, "DapThread", { fg = "#FFFFFF" })
vim.api.nvim_set_hl(0, "DapFrame", { fg = "#BBBBBB" })

return Threads
