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
  for buf, bpoints in pairs(require("dap.breakpoints").get()) do
    for _, point in ipairs(bpoints) do
      vim.print(buf, point)
    end
  end
end

return Breakpoints
