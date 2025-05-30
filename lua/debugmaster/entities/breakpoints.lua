local api = vim.api
local bps = require("dap.breakpoints")
local dap = require("dap")
local tree = require("debugmaster.lib.tree")
local SessionsManager = require("debugmaster.managers.SessionsManager")
local dispatcher = tree.dispatcher
local breakpoints = {}

---@alias dm.Bp {handler: dm.TreeNodeEventHandler, line: number, condition?: string, buf: number}
---@alias dm.BpRootNode {handler: dm.TreeNodeEventHandler}
---@alias dm.BpTreeNode dm.BpRootNode | dm.Bp

breakpoints.root_handler = dispatcher.new {
  render = function(_, event)
    event.out.lines = {
      { { "BREAKPOINTS:", "WarningMsg" } },
      { { "1. t - remove breakpoint ", "Comment" }, { "2. c - change breakpoint condition", "Comment" } },
    }
  end,
  keymaps = {}
}

breakpoints.bp_handler = dispatcher.new {
  ---@param node dm.Bp
  render = function(node, event)
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
  ---@type table<string, fun(node: dm.Bp, event: dm.TreeNodeKeymapEvent)>
  keymaps = {
    c = function(node, _)
      vim.ui.input({ prompt = "New condition: ", default = node.condition or "" }, function(condition)
        SessionsManager.set({ condition = condition }, node.buf, node.line)
      end)
    end,
    t = function(node, _)
      SessionsManager.remove_breakpoints({ node })
    end,
    ["<CR>"] = function(node, event)
      local win = vim.fn.win_getid(vim.fn.winnr('#'))
      if win == 0 then
        win = api.nvim_open_win(node.buf, true, { split = "left", win = -1 })
      end
      api.nvim_win_set_buf(win, node.buf)
      api.nvim_win_set_cursor(win, { node.line, 0 })
    end
  }
}

---@param bp_list dm.Breakpoint[]
---@return dm.Breakpoint[]
function breakpoints.build_bps(bp_list)
  local children = {}
  for _, bp in pairs(bp_list --[=[@as dm.Bp[]]=]) do
    bp.handler = breakpoints.bp_handler
    table.insert(children, bp)
  end
  return children
end

return breakpoints
