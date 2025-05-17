---@diagnostic disable: undefined-field
-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md

---@module "mini.test"

local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local api = vim.api

local T = MiniTest.new_set()

T["it renders"] = new_set()

T["it renders"]["nothing"] = function()
  local tree = require("debugmaster.lib.tree")
  local root = { children = { {}, {} } }
  local tr = tree.new { root = root, renderer = function() end }
  expect.equality(tr.snapshot.len, 0)
  expect.equality(#tr.snapshot.nodes_by_line, 0)
  expect.equality(#api.nvim_buf_get_lines(tr.buf, 0, -1, false), 1)
end

T["it renders"]["tree"] = function()
  local tree = require("debugmaster.lib.tree")
  local root = {
    value = "a",
    children = {
      { value = "b", },
      { value = "c" },
    },
  }
  local tr = tree.new {
    root = root,
    renderer = function(cur, depth)
      return { { string.rep(" ", depth) }, { cur.value } }
    end,
  }
  expect.equality(tr.snapshot.len, 3)
  ---TODO: make it 1 indexed
  expect.equality(tr.snapshot.nodes_by_line[1].value, "a")
  expect.equality(tr.snapshot.nodes_by_line[2].value, "b")
  expect.equality(tr.snapshot.nodes_by_line[3].value, "c")
end




return T
