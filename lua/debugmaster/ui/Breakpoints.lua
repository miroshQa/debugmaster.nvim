local dap = require("dap")
local breakpoints = require("dap.breakpoints")
local Tree = require("debugmaster.ui.Tree")

---@class dm.BreakpointNode: dm.NodeTrait
local BreakpointNode = {}

---@param bpoints {buf: number, bpoints: any}?
function BreakpointNode.new(bpoints, bpoint)
  ---@class dm.BreakpointNode
  local self = setmetatable({}, { __index = BreakpointNode })
  self.id = "first"
  self.bpoints = bpoints
  self.bpoint = bpoint
  if bpoints or bpoint then
    self.id = bpoints and ("buf" .. bpoints.buf) or ("bp" .. bpoint.line)
  end
  return self
end

function BreakpointNode:get_children_iter()
  if not self.bpoint and not self.bpoints then
    return coroutine.wrap(function()
      for buf, bpoints in pairs(breakpoints.get()) do
        coroutine.yield(BreakpointNode.new({ buf = buf, bpoints = bpoints }))
      end
    end)
  elseif self.bpoints then
    return vim.iter(self.bpoints.bpoints):map(function(b)
      b.buf = self.bpoints.buf
      return BreakpointNode.new(nil, b)
    end)
  end
  return function() end
end

function BreakpointNode:get_repr()
  if not self.bpoints and not self.bpoint then
    local help = {
      { { "x - remove breakpoint", "Comment"} }
    }
    return { { "Breakpoints", "Exception" } }, help
  elseif self.bpoints then
    local path = vim.api.nvim_buf_get_name(self.bpoints.buf)
    path = vim.fn.fnamemodify(path, ":.")
    return { { path, "Statement" } }
  else
    local indent = "    "
    local linenr = self.bpoint.line
    local line = vim.trim(vim.api.nvim_buf_get_lines(self.bpoint.buf, linenr - 1, linenr, false)[1])
    local text = string.format("%s %s %s", indent, linenr, line)
    return { { text } }
  end
end

function BreakpointNode:is_expanded()
  return true
end

---@class dm.ui.Breakpoints: dm.ui.Sidepanel.IComponent
local Breakpoints = {}

function Breakpoints.new()
  ---@class dm.ui.Breakpoints
  local self = setmetatable({}, { __index = Breakpoints })
  self.name = "[B]points"
  self._tree = Tree.new_with_buf(BreakpointNode.new())
  self.buf = self._tree.buf

  dap.listeners.after.setBreakpoints["debugmaster"] = function(session)
    self._tree:render()
  end

  return self
end

return Breakpoints
