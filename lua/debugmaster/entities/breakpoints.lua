local api = vim.api
local bps = require("dap.breakpoints")
local tree = require("debugmaster.lib.tree")
local SessionsManager = require("debugmaster.managers.SessionsManager")
local dispatcher = tree.dispatcher
local breakpoints = {}

---@alias dm.Bp {kind: "bp", line: number, condition?: string, buf: number}
---@alias dm.BprootRoot {kind: "root"}
---@alias dm.BpTreeNode dm.BprootRoot | dm.Bp


breakpoints.root_handler = dispatcher.new {
  render = function(event)
    event.out.lines = {
      { { "BREAKPOINTS:", "WarningMsg" } },
      { { "t - remove breakpoint", "Comment" }, { "c - change breakpoint condition", "Comment" } },
    }
  end,
  keymaps = {}
}

breakpoints.bp_handler = dispatcher.new {
  render = function(event)
    local node = event.cur
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
    event.out.lines = lines
  end,
  keymaps = {
    c = function(event)
      local cur = event.cur
      local condition = vim.fn.input({ default = cur.condition or "" })
      bps.set({ condition = condition }, cur.buf, cur.line)
    end,
    t = function(event)
      breakpoints.remove_bp(event.cur)
    end,
    ["<CR>"] = function(event)
    end
  }
}

---@param bp_list dm.Breakpoint[]
---@return dm.Breakpoint[]
function breakpoints.build_bps(bp_list)
  local children = {}
  for _, bp in pairs(bp_list) do
    ---@type dm.Bp[]
    bp.handler = breakpoints.bp_handler
    bp.kind = "bp"
    table.insert(children, bp)
  end
  return children
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

return breakpoints
