local dap = require("dap")
local scopes = require("debugmaster.entities.scopes")

local watches = {}

function watches.fetch_expression()
  local expression = { handler = scopes.var_handler }
  local s = assert(dap.session())
  s:request("evaluate", nil, function(err, result)
  end)
end

return watches
