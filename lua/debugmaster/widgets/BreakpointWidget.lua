local api = vim.api

---@class dm.BreakpointWidget: dm.Widget, dm.Breakpoint
local BreakpointWidget = {}
---@private
BreakpointWidget.__index = BreakpointWidget

---@type dm.WidgetRenderer
function BreakpointWidget:render(out)
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

---@type table<string, fun(self: dm.BreakpointWidget, view: dm.TreeView)>
BreakpointWidget.keymaps = {
  c = function(self)
    local SessionsManager = require("debugmaster.managers.SessionsManager")
    vim.ui.input({ prompt = "New condition: ", default = self.condition or "" }, function(condition)
      SessionsManager.set({ condition = condition }, self.buf, self.line)
    end)
  end,
  t = function(self)
    local SessionsManager = require("debugmaster.managers.SessionsManager")
    SessionsManager.remove_breakpoints { self }
  end,
  ["<CR>"] = function(self)
    local win = vim.fn.win_getid(vim.fn.winnr("#"))
    if win == 0 then
      win = api.nvim_open_win(self.buf, true, { split = "left", win = -1 })
    end
    api.nvim_win_set_buf(win, self.buf)
    api.nvim_win_set_cursor(win, { self.line, 0 })
  end
}


return BreakpointWidget
