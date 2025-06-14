---@module "dap"

local uv = vim.uv
local async = require("debugmaster.lib.async")
local common = require("debugmaster.widgets.common")

---@class dm.VariableWidget: dm.Widget, dap.Variable
---@field children dm.VariableWidget[]? No children means not loaded
---@field child_by_name table<string, dm.VariableWidget>?
---@field session dap.Session
local VariableWidget = {}
---@private
VariableWidget.__index = VariableWidget


local types_to_hl_group = {
  boolean = "Boolean",
  string = "String",
  int = "Number",
  long = "Number",
  number = "Number",
  double = "Float",
  float = "Float",
  ["function"] = "Function",
}

---@type dm.WidgetRenderer
function VariableWidget:render(out, parent, depth)
  local icon = self.collapsed and " " or " "
  icon = (not self.variablesReference or self.variablesReference == 0) and "" or icon
  local indent = string.rep(" ", depth)
  local lines = vim.split(self.value, "\n")
  out.lines = {
    { { indent }, { icon }, { self.name, "Exception" }, { " = " } }
  }
  if #lines == 1 then
    table.insert(out.lines[1], { self.value, types_to_hl_group[self.type] })
  else
    for _, line in ipairs(lines) do
      table.insert(out.lines, { { line, "Comment" } })
    end
  end
end

---@param session dap.Session
---@param var dap.Variable
---@return dm.VariableWidget
function VariableWidget.new(session, var)
  local self = setmetatable(vim.deepcopy(var), VariableWidget)
  self.collapsed = true
  self.session = session
  ---@diagnostic disable-next-line: return-type-mismatch
  return self
end

---Load varialles if not loaded and has variable references. Cb called on done.
---@param cb fun()
function VariableWidget:load(cb)
  if (self.variablesReference or -1) < 1 or self.children then
    return cb()
  end
  self.children = {}
  self.child_by_name = {}
  local req = { variablesReference = self.variablesReference }
  self.session:request("variables", req, function(err, result)
    assert(not err)
    for _, v in ipairs(result.variables) do
      local var = VariableWidget.new(self.session, v)
      self.child_by_name[var.name] = var
      table.insert(self.children, var)
    end
    cb()
  end)
end

---@param timeout integer
---@param cb fun()
function VariableWidget:load_recursive(timeout, cb)
  local timer = assert(uv.new_timer())
  local should_stop = false
  timer:start(timeout, 0, function()
    should_stop = true
    timer:close()
  end)

  ---@param node dm.VariableWidget
  local function load_recursive_internal(node, current_depth, done_cb)
    if node.variablesReference < 1 or should_stop then
      return done_cb()
    end

    local function load_children()
      local tasks = {}
      for _, child in ipairs(node.children) do
        table.insert(tasks, function(on_done)
          load_recursive_internal(child, current_depth + 1, on_done)
        end)
      end
      print("amount of tasks: ", #tasks, "depth: ", current_depth)
      async.await_all(tasks, done_cb)
    end

    if not node.children then
      node:load(function()
        load_children()
      end)
    else
      load_children()
    end
  end

  load_recursive_internal(self, 0, cb)
end

---@type table<string, fun(self: dm.VariableWidget, canvas: dm.Canvas)>
VariableWidget.keymaps = {
  ["<CR>"] = function(self, canvas)
    self:load(function()
      self.collapsed = not self.collapsed
      canvas.notify_about_change(self)
    end)
  end,
  r = function(self, canvas)
    print("launch recurvie expand")
    self:load_recursive(500, function()
      canvas.notify_about_change(self)
      print("recursive expand finished")
    end)
  end,
}

return VariableWidget
