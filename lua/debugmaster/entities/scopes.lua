local dap               = require("dap")
local api               = vim.api
local uv                = vim.uv
local async             = require("debugmaster.lib.async")

local scopes            = {}

scopes.toggle_variables = function(node, view)
  local s = dap.session()
  node.collapsed = not node.collapsed
  if s and (node.variablesReference or -1) > 0 and not node.children then
    scopes.load_variables(s, node, function()
      node.collapsed = false
      view:refresh(node)
    end)
  else
    view:refresh(node)
  end
end


---No children means not loaded
---@class dm.Variable: dm.TreeNode, dap.Variable
---@field children dm.Variable[]
---@field child_by_name table<string, dm.Variable>
local Variable   = {}
---@private
Variable.__index = Variable

---@type dm.TreeNodeRenderer
function Variable:render(out, parent, depth)
  local icon = self.collapsed and " " or " "
  icon = (not self.variablesReference or self.variablesReference == 0) and "" or icon
  local indent = string.rep(" ", depth)
  local lines = vim.split(self.value, "\n")
  out.lines = {
    { { indent }, { icon }, { self.name, "Exception" }, { " = " } }
  }
  if #lines == 1 then
    table.insert(out.lines[1], { self.value, scopes.types_to_hl_group[self.type] })
  else
    for _, line in ipairs(lines) do
      table.insert(out.lines, { { line, "Comment" } })
    end
  end
end

---@type table<string, fun(node: dm.Variable, view: dm.TreeView)>
Variable.keymaps = {
  ["<CR>"] = scopes.toggle_variables,
  K = function(node)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(vim.inspect(node), "\n"))
    vim.treesitter.start(buf, "lua")
    require("debugmaster.lib.view").popup.new { buf = buf }
  end,
  r = function(node, view)
    print("launch recurvie expand")
    scopes.expand_recursive(node, function()
      view:refresh(node)
      print("recursive expand finished")
    end, 500)
  end,
  d = function(node, view)
    local UiManager = require("debugmaster.managers.UiManager")
    UiManager.watches.remove(node)
    view:refresh(UiManager.watches.root)
  end,
  a = function(node, view)
    if node.evaluateName then
      local UiManager = require("debugmaster.managers.UiManager")
      UiManager.watches.add(node.evaluateName, function()
        view:refresh(UiManager.watches.root)
      end)
    else
      print("no evaluateName!")
    end
  end
}

---No children means not loaded
---@class dm.Scope: dm.TreeNode, dap.Scope
---@field child_by_name table<string, dm.Variable>
---@field children dm.Variable[]
local Scope      = {}
---@private
Scope.__index    = Scope

---@type dm.TreeNodeRenderer
function Scope:render(out)
  local icon = self.collapsed and " " or " "
  icon = self.variablesReference == 0 and "" or icon
  out.lines = {
    { { icon }, { self.name } },
  }
end

Scope.keymaps = {
  ["<CR>"] = scopes.toggle_variables
}

---@param node dm.Variable
---@param cb fun()
---@param timeout integer
function scopes.expand_recursive(node, cb, timeout)
  local timer = assert(uv.new_timer())
  local should_stop = false
  timer:start(timeout, 0, function()
    should_stop = true
    timer:close()
    -- print("STOP STOP!!!")
  end)

  local function expand_recursive_internal(n, current_depth, done_cb)
    if n.variablesReference < 1 or should_stop then
      return done_cb()
    end

    local function expand_children()
      local tasks = {}
      for _, child in ipairs(n.children) do
        table.insert(tasks, function(on_done)
          expand_recursive_internal(child, current_depth + 1, on_done)
        end)
      end
      print("amount of tasks: ", #tasks, "depth: ", current_depth)
      async.await_all(tasks, done_cb)
    end

    local s = assert(dap.session())
    if not n.children then
      scopes.load_variables(s, n, expand_children)
    else
      expand_children()
    end
    n.collapsed = false
  end

  expand_recursive_internal(node, 0, cb)
end

---Load varialles. Erase all previous children. Cb called on done.
---@param s dap.Session
---@param target dm.Variable | dm.Scope
---@param cb fun()
function scopes.load_variables(s, target, cb)
  assert(target.variablesReference ~= 0, "variables refernece == 0. can't load variables!!")
  local req = { variablesReference = target.variablesReference }
  s:request("variables", req, function(err, result)
    assert(not err)
    target.children = {}
    target.child_by_name = {}
    -- NOTE: should consider deep copy?
    for _, var in ipairs(result.variables --[=[@as dm.Variable[]]=]) do
      target.child_by_name[var.name] = var
      table.insert(target.children, setmetatable(var, Variable))
    end
    cb()
  end)
end

---Fetch all scopes. Return list of scopes via cb on done
---@param s dap.Session
---@param frame dap.StackFrame
---@param cb fun(res: dm.Scope[])
function scopes.fetch_frame(s, frame, cb)
  local results = {}
  ---@param err any
  ---@param result dap.ScopesResponse
  s:request("scopes", { frameId = frame.id }, function(err, result)
    assert(not err)
    local tasks = {}
    for _, scope in ipairs(result.scopes --[=[@as dm.Scope[]]=]) do
      scope.children = {}
      scope.collapsed = scope.name ~= "Locals"
      table.insert(results, setmetatable(scope, Scope))
      table.insert(tasks, function(on_done)
        scopes.load_variables(s, scope, on_done)
      end)
    end

    async.await_all(tasks, function()
      cb(results)
    end)
  end)
end

---@param s dap.Session
---@param from dm.Scope | dm.Variable
---@param to dm.Scope | dm.Variable
---@param cb fun() called on done
---Resolve all refrences variables refrences for nodes if children exist
function scopes.sync_variables(s, from, to, cb)
  assert(from.name == to.name, string.format("from.name: %s ~= to.name: %s", from.name, to.name))
  to.collapsed = from.collapsed
  if not from.children then
    return cb()
  end

  scopes.load_variables(s, to, function()
    local tasks = {}

    for _, child_to in ipairs(to.children) do
      local child_from = from.child_by_name[child_to.name]
      if child_from then
        table.insert(tasks, function(on_done)
          scopes.sync_variables(s, child_from, child_to, on_done)
        end)
      end
    end

    async.await_all(tasks, cb)
  end)
end

---@class dm.EvaluateResult
---@field name string
---@field value string
---@field variablesReference number?
---@field evaluateName string

---@param req dap.EvaluateArguments
---@param cb fun(res: dm.EvaluateResult)
---@param base dm.EvaluateResult?
function scopes.eval(req, cb, base)
  local s = assert(dap.session())
  local res = base or {}
  req.frameId = s.current_frame.id
  req.context = "repl"
  s:request("evaluate", req, function(err, result)
    result = result or {}
    res.name = req.expression
    res.value = result.result or (err.message or "unknown evaluation error")
    res.variablesReference = result.variablesReference
    res.evaluateName = res.name
    setmetatable(res, Variable)
    cb(res)
  end)
end

---@param s dap.Session
---@param from dm.Scope[]
---@param to dm.Scope[]
---@param cb fun() on done
function scopes.sync_scopes(s, from, to, cb)
  local from_child_by_name = {}
  for _, from_child in ipairs(from) do
    from_child_by_name[from_child.name] = from_child
  end

  local tasks = {}
  for _, to_scope in ipairs(to) do
    local from_scope = from_child_by_name[to_scope.name]
    if from_scope then
      table.insert(tasks, function(on_done)
        scopes.sync_variables(s, from_scope, to_scope, on_done)
      end)
    end
  end
  async.await_all(tasks, cb)
end

scopes.types_to_hl_group = {
  boolean = "Boolean",
  string = "String",
  int = "Number",
  long = "Number",
  number = "Number",
  double = "Float",
  float = "Float",
  ["function"] = "Function",
}

scopes.Scope = Scope
scopes.Variable = Variable

return scopes
