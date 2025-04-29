local dap = require("dap")
local breakpoints = require("dap.breakpoints")
local Tree = require("debugmaster.ui.Tree")
local api = vim.api

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
      { { "t - remove breakpoint or all breakpoints in the file", "Comment" } },
      { { "c - change breakpoint condition", "Comment" } }
    }
    return { { "Breakpoints", "Exception" } }, help
  elseif self.bpoints then
    local path = api.nvim_buf_get_name(self.bpoints.buf)
    path = vim.fn.fnamemodify(path, ":.")
    return { { path, "Statement" } }
  else
    local vlines = nil
    local indent = "    "
    local linenr = self.bpoint.line
    local line = vim.trim(api.nvim_buf_get_lines(self.bpoint.buf, linenr - 1, linenr, false)[1])
    local text = string.format("%s %s %s", indent, linenr, line)
    local condition = self.bpoint.condition
    if condition and condition ~= "" then
      vlines = { { { indent }, { "condition: ", "Comment" }, { self.bpoint.condition } } }
    end
    return { { text } }, vlines
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

  vim.keymap.set("n", "c", function()
    local line = api.nvim_win_get_cursor(0)[1] - 1
    ---@type dm.BreakpointNode?
    local node = self._tree:node_by_line(line)
    if node and node.bpoint then
      local bp = node.bpoint
      local condition = vim.fn.input({ default = bp.condition or "" })
      breakpoints.set({ condition = condition }, bp.buf, bp.line)
      self._tree:render()
    end
  end, { buffer = self.buf, nowait = true })


  vim.keymap.set("n", "t", function()
    local line = api.nvim_win_get_cursor(0)[1] - 1
    ---@type dm.BreakpointNode?
    local node = self._tree:node_by_line(line)
    if node then
      if node.bpoint then
        local bp = node.bpoint
        breakpoints.remove(bp.buf, bp.line)
        for _, session in pairs(dap.sessions()) do
          session:set_breakpoints(breakpoints.get(bp.buf))
        end
      elseif node.bpoints then
        local bps = node.bpoints or {}
        for _, bp in pairs(bps.bpoints) do
          breakpoints.remove(bps.buf, bp.line)
          for _, session in pairs(dap.sessions()) do
            session:set_breakpoints(breakpoints.get(bp.buf))
          end
        end
      end
      self._tree:render()
    end
  end, { buffer = self.buf, nowait = true })

  vim.keymap.set("n", "<CR>", function()
    local line = api.nvim_win_get_cursor(0)[1] - 1
    ---@type dm.BreakpointNode?
    local node = self._tree:node_by_line(line)
    if node then
      if node.bpoint then
        local bp = node.bpoint
        breakpoints.remove(bp.buf, bp.line)
        vim.cmd("q")
        vim.cmd("buffer " .. bp.buf)
        vim.cmd("normal " .. bp.line .. "G")
      end
    end
  end)

  dap.listeners.after.setBreakpoints["debugmaster"] = function()
    self._tree:render()
  end

  return self
end

return Breakpoints
