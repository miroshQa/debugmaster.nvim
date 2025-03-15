local widgets = require('dap.ui.widgets')

---@class debugmaster.ui.Scopes: debugmaster.ui.Sidepanel.IComponent
local Scopes = {}

function Scopes.new()
  ---@class debugmaster.ui.Scopes
  local self = setmetatable({}, {__index = Scopes})
  local scopes = widgets.sidebar(widgets.scopes)
  local scopes_buf, scopes_win = scopes.open()
  vim.api.nvim_win_close(scopes_win, true)
  self.buf = scopes_buf
  self.name = "[S]copes"
  vim.keymap.set("n", "<Tab>", "<CR>", {buffer = self.buf, remap = true})
  return self
end

return Scopes
