local api = vim.api
local async = require("debugmaster.lib.async")

local common = {}

function common.inspect(node)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(iinspect(node, ignore), "\n"))
  vim.treesitter.start(buf, "lua")
  require("debugmaster.lib.view").popup.new { buf = buf }
end

---@class dm.LazyWidget: dm.Widget Accept generic param (LazyWidget<T>)
---@field child_by_name table<string, dm.LazyWidget>
---@field load fun(self: dm.LazyWidget, cb: fun())

function common.sync(to, from, cb)
  to.collapsed = from.collapsed
  if not from.children then
    return cb()
  end

  to:load(function()
    if not to.children then
      return cb()
    end
    local tasks = {}
    for _, child in ipairs(to.children) do
      local counterpart = from.child_by_name[child.name]
      if counterpart then
        table.insert(tasks, function(on_done)
          common.sync(child, counterpart, on_done)
        end)
      end
    end

    async.await_all(tasks, cb)
  end)
end

return common
