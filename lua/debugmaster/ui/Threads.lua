local dap = require("dap")

---@class debugmaster.ui.Threads: debugmaster.ui.Sidepanel.IComponent
local Threads = {}

function Threads.new()
  ---@class debugmaster.ui.Threads
  local self = setmetatable({}, { __index = Threads })
  self.name = "[T]hreads"
  self.buf = vim.api.nvim_create_buf(false, true)
  self._hl_ns = vim.api.nvim_create_namespace("HelpPopupHighlightNamespace")

  dap.listeners.after.stackTrace["debugmaster"] = function(session)
    self:_update(session)
  end

  return self
end

---@param session dap.Session
function Threads:_update(session)
  local lines = {}
  local highlights = {}
  for _, thread in pairs(session.threads) do
    local indent = "    "
    table.insert(lines, thread.name)
    for _, frame in ipairs(thread.frames or {}) do
      table.insert(lines, indent .. frame.name)
      if frame.id == session.current_frame.id then
        table.insert(highlights, {hlgroup = "Exception", index = #lines - 1})
      end
    end
  end

  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(self.buf, self._hl_ns, hl.hlgroup, hl.index, 0, -1)
  end
end

return Threads
