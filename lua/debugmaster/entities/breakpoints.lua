local api = vim.api
local breakpoints = {}

---@class dm.Breakpoint: dm.TreeNode
local Breakpoint = {}
---@private
Breakpoint.__index = Breakpoint

---@class dm.Breakpoint
---@field buf number
---@field condition string?
---@field line number
---@field hitCondition string
---@field logMessage string

---@type dm.TreeNodeRenderer
function Breakpoint:render(out)
  local indent = "    "
  local linenr = self.line
  local line = vim.trim(api.nvim_buf_get_lines(self.buf, linenr - 1, linenr, false)[1])
  local text = string.format("%s %s %s", indent, linenr, line)
  local condition = self.condition
  local lines = {
    { { text } },
  }
  if condition and condition ~= "" then
    table.insert(lines, { { indent }, { "condition: ", "Comment" }, { self.condition } })
  end
  out.lines = lines
end

---@type table<string, fun(node: dm.Breakpoint, view: dm.TreeView)>
Breakpoint.keymaps = {
  c = function(node)
    local SessionsManager = require("debugmaster.managers.SessionsManager")
    vim.ui.input({ prompt = "New condition: ", default = node.condition or "" }, function(condition)
      SessionsManager.set({ condition = condition }, node.buf, node.line)
    end)
  end,
  t = function(node)
    local SessionsManager = require("debugmaster.managers.SessionsManager")
    SessionsManager.remove_breakpoints { node }
  end,
  ["<CR>"] = function(node)
    local win = vim.fn.win_getid(vim.fn.winnr("#"))
    if win == 0 then
      win = api.nvim_open_win(node.buf, true, { split = "left", win = -1 })
    end
    api.nvim_win_set_buf(win, node.buf)
    api.nvim_win_set_cursor(win, { node.line, 0 })
  end
}

breakpoints.Breakpoint = Breakpoint

return breakpoints
