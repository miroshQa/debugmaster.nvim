local api = vim.api
local tree = require("debugmaster.ui.tree")
-- need to rewrite it in the future, so scopse module didn't know about 
-- dap at all, it absolutes isn't his responsibility. It just should accept data (scopes)
-- from some function like Scopes.render(scopes) and render it
local dap = require("dap")
local after = dap.listeners.after
local before = dap.listeners.before
local id = "debugmaster"

local Scopes = {}

function Scopes.new()
---@class dm.ui.Scopes: dm.ui.Sidepanel.IComponent
  local self = {}
  self.buf = vim.api.nvim_create_buf(false, true)
  self.name = "[S]copes"

  ---@param s any
  ---@param err any
  ---@param res dap.ScopesResponse
  ---@param _ any
  ---@param req_id any
  after.scopes[id] = function(s, err, res, _, req_id)
  end

  ---@param res dap.VariableResponse
  after.variables[id] = function (s, err, res, _, _)
    vim.print(res)
  end

  api.nvim_create_autocmd("User", {
    pattern = "DapSessionChanged",
    callback = vim.schedule_wrap(function()
    end)
  })

  return self
end

return Scopes
