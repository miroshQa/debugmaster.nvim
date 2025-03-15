local dap = require("dap")

---@class debugmaster.ui.Breakpoints: debugmaster.ui.Sidepanel.IComponent
local Breakpoints = {}

function Breakpoints.new()
  ---@class debugmaster.ui.Breakpoints
  local self = setmetatable({}, {__index = Breakpoints})
  self.name = "[B]points"
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {"Some breakponts here"})


  dap.listeners.after.setBreakpoints["debugmaster"] = function(session)
    self:_update(session)
  end

  return self
end

---@param session dap.Session
function Breakpoints:_update(session)
  local lines = {}
  for buf, bpoints in pairs(require("dap.breakpoints").get()) do
    local indent = "    "
    local path = vim.api.nvim_buf_get_name(buf)
    path = vim.fn.fnamemodify(path, ":.")
    table.insert(lines, path)
    for _, point in ipairs(bpoints) do
      local linenr = point.line
      local line = vim.trim(vim.api.nvim_buf_get_lines(buf, linenr - 1, linenr, false)[1])
      table.insert(lines, string.format("%s %s %s", indent, linenr, line))
    end
  end
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
end

return Breakpoints
