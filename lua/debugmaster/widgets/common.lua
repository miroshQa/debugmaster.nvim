local api = vim.api
local async = require("debugmaster.lib.async")

local common = {}

---@class dm.LoadableWidge

function common.inspect(node)
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(vim.inspect(node), "\n"))
  vim.treesitter.start(buf, "lua")
  require("debugmaster.lib.view").popup.new { buf = buf }
end

---@class dm.LazyWidget: dm.Widget Accept generic param (LazyWidget<T>)
---@field child_by_name table<string, dm.LazyWidget>
---@field load fun(self: dm.LazyWidget, cb: fun())

function common.sync(self, from, cb)
  self.collapsed = from.collapsed
  if not from.children then
    return cb()
  end

  print("starting loading")
  self:load(function()
    print("loading end")
    if not self.children then
      print("self doesn't have children")
      return cb()
    end
    local tasks = {}
    for _, child in ipairs(self.children) do
      local counterpart = from.child_by_name[child.name]
      if counterpart then
        table.insert(tasks, function(on_done)
          child:sync(counterpart, on_done)
        end)
      end
    end

    async.await_all(tasks, cb)
  end)
end

return common
