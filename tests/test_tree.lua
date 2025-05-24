---@diagnostic disable: undefined-field
-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md

---@module "mini.test"

local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local api = vim.api
local tree = require("debugmaster.lib.tree")

local T = MiniTest.new_set()

local function handerlify(root, h)
  root.handler = h
  if root.children and not root.collapsed then
    for _, child in ipairs(root.children) do
      handerlify(child, h)
    end
  end
  return root
end

---@type dm.TreeNodeEventHandler
local generic_handler = function(event)
  if event.name == "render" then
    event.out.lines = { { { event.node.value } } }
  end
end

local function expect_render(view, expected_lines)
  local lines = api.nvim_buf_get_lines(view.snapshot.buf, 0, -1, false)
  local throw_error = function()
    error(string.format("\nview buffer: \n-----\n%s\n-----\nexpected:\n-----\n%s\n------\n",
      vim.inspect(lines),
      vim.inspect(expected_lines)))
  end
  if #expected_lines ~= #lines then
    throw_error()
  end
  for i, line in ipairs(lines) do
    local expected_line = expected_lines[i]
    if not line == expected_line then
      throw_error()
    end
  end
end


T["it renders"] = new_set()

T["it renders"]["nothing"] = function()
  local root = { children = { {}, {} } }
  local view = tree.view.new { root = root, keymaps = {} }
  expect.equality(view.snapshot.nodes_info[view.root].len, 0)
  expect.equality(view.snapshot.nodes_info[view.root].extmark_id, 0)
end


T["it renders"]["tree"] = function()
  local root = {
    value = "a",
    children = {
      { value = "b" },
      { value = "c" },
    }
  }
  handerlify(root, generic_handler)
  local view = tree.view.new { root = root, keymaps = {} }
  expect.equality(view.snapshot.nodes_info[view.root].len, 3)
  expect.equality(view.snapshot:get(0).value, "a")
  expect.equality(view.snapshot:get(1).value, "b")
  expect.equality(view.snapshot:get(2).value, "c")
end


T["it renders"]["partially"] = function()
  local root = {
    value = "a",
    children = {
      {
        value = "b",
        children = {
          { value = "b1" },
          { value = "b2" },
        }
      },
      {
        value = "c",
        children = {
          { value = "c1" },
          { value = "c2" },
        }
      },
    },
  }
  handerlify(root, generic_handler)
  local view = tree.view.new { root = root, keymaps = {} }
  expect.equality(view.snapshot.nodes_info[view.root].len, 7)
  expect.equality(view.snapshot.nodes_info[root.children[1]].len, 3)
  expect_render(view, { "a", "b", "b1", "b2", "c", "c1", "c2" })

  root.children[1].collapsed = true
  view:refresh(root.children[1])
  expect_render(view, { "a", "b", "c", "c1", "c2" })
  expect.equality(view.snapshot.nodes_info[root].len, 5)

  root.children[1].collapsed = false
  view:refresh(root.children[1])
  expect.equality(view.snapshot.nodes_info[view.root].len, 7)
  expect.equality(view.snapshot.nodes_info[root.children[1]].len, 3)
  expect_render(view, { "a", "b", "b1", "b2", "c", "c1", "c2" })
end


T["it renders"]["tree with concealed node"] = function()
  local root = {
    values = {
      { { "a1" } },
      { { "a2" } },
    },
    children = {
      { values = { { { "b" } } }, conceal = true },
      { values = { { { "c" } } } },
    }
  }
  handerlify(root, function(event)
    if event.name == "render" and not event.node.conceal then
      event.out.lines = event.node.values
    end
  end)
  local view = tree.view.new { root = root, keymaps = {} }
  expect_render(view, { "a1", "a2", "c" })
  local b = root.children[1]
  b.conceal = false
  view:refresh(b)
  expect_render(view, { "a1", "a2", "b", "c" })
end



return T
