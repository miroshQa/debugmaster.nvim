local api = vim.api
local bps = require("dap.breakpoints")
local tree = require("debugmaster.lib.tree")
local SessionsManager = require("debugmaster.managers.SessionsManager")
local dispatcher = tree.dispatcher
local breakpoints = {}

---@alias dm.Bp {kind: "bp", line: number, condition?: string, buf: number}
---@alias dm.BpDummyRoot {kind: "dummy"}
---@alias dm.BpTreeNode dm.BpDummyRoot | dm.Bp


breakpoints.renderer = dispatcher.renderer.new {
  ---@param node dm.BpDummyRoot
  dummy = function(node, depth, parent)
    return {
      { { "Breakpoints", "Exception" } },
      { { "t - remove breakpoint or all breakpoints in the file", "Comment" } },
      { { "c - change breakpoint condition", "Comment" } }
    }
  end,
  ---@param node dm.Bp
  bp = function(node, depth, parent)
    local indent = "    "
    local linenr = node.line
    local line = vim.trim(api.nvim_buf_get_lines(node.buf, linenr - 1, linenr, false)[1])
    local text = string.format("%s %s %s", indent, linenr, line)
    local condition = node.condition
    local lines = {
      { { text } },
    }
    if condition and condition ~= "" then
      table.insert(lines, { { indent }, { "condition: ", "Comment" }, { node.condition } })
    end
    return lines
  end
}

---@param bp_list dm.Breakpoint[]
function breakpoints.build_tree(bp_list)
  ---@type dm.BpDummyRoot
  local root = {
    kind = "dummy",
    expanded = true,
    children = {},
  }
  for _, bp in pairs(bp_list) do
    ---@type dm.Bp[]
    bp.kind = "bp"
    table.insert(root.children, bp)
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
  end
end

---@alias dm.BpTreeNodeAction fun(cur: dm.BpTreeNode, tr: dm.TreeView)

---@type table<string, dm.BpTreeNodeAction>
breakpoints.actions = {
  ["c"] = function(cur, _)
    if cur.kind == "bp" then
      local condition = vim.fn.input({ default = cur.condition or "" })
      bps.set({ condition = condition }, cur.buf, cur.line)
    end
  end,
  ["t"] = function(cur)
    breakpoints.remove_bp(cur)
  end,
  ["<CR>"] = function(cur, v)
    v.tree = breakpoints.build_tree(bps.get())
    v:refresh()
    if cur.kind == "bp" then
      bps.remove(cur.buf, cur.line)
      vim.cmd("q")
      vim.cmd("buffer " .. cur.buf)
      vim.cmd("normal " .. cur.line .. "G")
    end
  end,
}

return breakpoints
