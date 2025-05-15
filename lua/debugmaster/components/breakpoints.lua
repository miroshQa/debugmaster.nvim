local api = vim.api
local bps = require("dap.breakpoints")
local tree = require("debugmaster.components.generic.tree")
local breakpoints = {}

---@alias dm.BpContainer {kind: "container", children: dm.Bp[], buf: number, expanded: boolean }
---@alias dm.Bp {kind: "bp", line: number, condition?: string, buf: number}
---@alias dm.BpDummyRoot {kind: "dummy"}
---@alias dm.BpTreeNode dm.BpContainer | dm.Bp


---@param node dm.BpTreeNode
function breakpoints.render_node(node)
  -- yeah {kind = "a"} or {kind = "b"} notation doesn't work indeed
  -- Please someone create good lsp server for lua please...
  if node.kind == "dummy" then
    local help = {
      { { "t - remove breakpoint or all breakpoints in the file", "Comment" } },
      { { "c - change breakpoint condition", "Comment" } }
    }
    return { { "Breakpoints", "Exception" } }, { vlines = help }
  elseif node.kind == "container" then
    local path = api.nvim_buf_get_name(node.buf)
    path = vim.fn.fnamemodify(path, ":.")
    return { { path, "Statement" } }
  else
    local vlines = nil
    local indent = "    "
    local linenr = node.line
    local line = vim.trim(api.nvim_buf_get_lines(node.buf, linenr - 1, linenr, false)[1])
    local text = string.format("%s %s %s", indent, linenr, line)
    local condition = node.condition
    if condition and condition ~= "" then
      vlines = { { { indent }, { "condition: ", "Comment" }, { node.condition } } }
    end
    return { { text } }, vlines
  end
end

---comment
---@param bps any must be require("dap.breakponts").get()
function breakpoints.build_tree(bps)
  ---@type dm.BpDummyRoot
  local root = {
    kind = "dummy",
    expanded = true,
    children = {},
  }
  for buf, bpoints in pairs(bps) do
    ---@type dm.Bp[]
    local children = {}
    for _, bp in ipairs(bpoints) do
      bp.buf = buf
      bp.kind = "bp"
      table.insert(children, bp)
    end
    ---@type dm.BpContainer
    local container = { children = children, expanded = true, buf = buf, kind = "container" }
    table.insert(root.children, container)
  end
  return root
end

---@param node dm.BpTreeNode
function breakpoints.remove_bp(node)
  local dap = require("dap")
  if node.kind == "bp" then
    bps.remove(node.buf, node.line)
    for _, session in pairs(dap.sessions()) do
      session:set_breakpoints(bps.get(node.buf))
    end
  elseif node.kind == "container" then
    for _, bp in pairs(node.children) do
      bps.remove(node.buf, bp.line)
      for _, session in pairs(dap.sessions()) do
        session:set_breakpoints(bps.get(bp.buf))
      end
    end
  end
end

function breakpoints.jump_to_bp(node)
end

---@class dm.BreakpointsTreeNodeHandler: dm.TreeNodeHandler
---@field action fun(cur: dm.BpTreeNode, tr: dm.Tree)

---@type dm.BreakpointsTreeNodeHandler[]
breakpoints.handlers = {
  {
    key = "c",
    action = function(cur, _)
      if cur.kind == "bp" then
        local condition = vim.fn.input({ default = cur.condition or "" })
        bps.set({ condition = condition }, cur.buf, cur.line)
      end
    end
  },
  {
    key = "t",
    action = function(cur)
      breakpoints.remove_bp(cur)
    end
  },
  {
    key = "<CR>",
    action = function(cur, tr)
      tr.root = breakpoints.build_tree(bps.get())
      tr:refresh()
      if cur.kind == "bp" then
        bps.remove(cur.buf, cur.line)
        vim.cmd("q")
        vim.cmd("buffer " .. cur.buf)
        vim.cmd("normal " .. cur.line .. "G")
      end
    end
  },
}


breakpoints.comp = (function()
  local bptree = tree.new(
    breakpoints.build_tree(bps.get()),
    { renderer = breakpoints.render_node })
  return {
    name = "[B]points",
    buf = bptree.buf,
  }
end)()


return breakpoints
