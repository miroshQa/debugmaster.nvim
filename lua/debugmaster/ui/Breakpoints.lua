local M = {}

---@class debugmaster.ui.Breakpoints: debugmaster.ui.Sidepanel.IComponent
local Breakpoints = {}

function M.new()
  ---@class debugmaster.ui.Breakpoints
  local self = setmetatable({}, {__index = Breakpoints})
  self.name = "[B]points"
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {"Some breakponts here"})
  return self
end

function Breakpoints:SomeMethod()
end

return M
