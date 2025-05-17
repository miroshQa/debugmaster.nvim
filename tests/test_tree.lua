-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md

---@module "mini.test"

local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local T = MiniTest.new_set()

T['works'] = function()
  local tree = require("debugmaster.components.generic.tree")
end

return T
