local widgets = require('dap.ui.widgets')
local api = vim.api

---@class dm.ui.Scopes: dm.ui.Sidepanel.IComponent
local Scopes = {}

function Scopes.new()
  ---@class dm.ui.Scopes
  local self = setmetatable({}, {__index = Scopes})
  local scopes = widgets.sidebar(widgets.scopes)
  local scopes_buf, scopes_win = scopes.open()
  api.nvim_win_close(scopes_win, true)
  self.buf = scopes_buf
  self.name = "[S]copes"
  vim.keymap.set("n", "<Tab>", "<CR>", {buffer = self.buf, remap = true})
  vim.keymap.del("n", "o", {buffer = self.buf })

  vim.keymap.set("n", "r", scopes.refresh, {buffer = self.buf})

  api.nvim_create_autocmd("User", {
    pattern = "DapSessionChanged",
    callback = vim.schedule_wrap(function()
      scopes.refresh()
    end)
  })

  return self
end

return Scopes
