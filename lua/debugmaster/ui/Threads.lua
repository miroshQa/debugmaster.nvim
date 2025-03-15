local dap = require("dap")
local M = {}

---@class debugmaster.ui.Threads: debugmaster.ui.Sidepanel.IComponent
local Threads = {}

function M.new()
  ---@class debugmaster.ui.Threads
  local self = setmetatable({}, { __index = Threads })
  self.name = "[T]hreads"
  self.buf = vim.api.nvim_create_buf(false, true)

  dap.listeners.after.stackTrace["debugmaster"] = function(session)
    print("stackTrace")
    self:_update(session)
  end

  return self
end

---@param session dap.Session
function Threads:_update(session)
  local lines = {}
  for _, thread in pairs(session.threads) do
    local indent = "    "
    table.insert(lines, thread.name)
    for _, frame in ipairs(thread.frames or {}) do
      table.insert(lines, indent .. frame.name)
    end
  end
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
end

function Threads:SomeMethod()
end

return M
