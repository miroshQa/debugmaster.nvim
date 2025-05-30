local dap = require("dap")
local api = vim.api
local uv = vim.uv
local tree = require("debugmaster.lib.tree")
local view = require("debugmaster.lib.view")
local async = require("debugmaster.lib.async")
local dispatcher = tree.dispatcher

local scopes = {}


---@class dm.ScopesNode: dap.Scope, dm.TreeNode
---@field children dm.VariablesNode[]? no children means not loaded
---@field collapsed boolean
---@field child_by_name table<string, dm.VariablesNode>

---@class dm.VariablesNode: dap.Variable, dm.TreeNode
---@field children dm.VariablesNode[]? no children means not loaded
---@field collapsed boolean
---@field child_by_name table<string, dm.VariablesNode>

---@alias dm.ScopesRoot {children: dm.StackFrameNode[]}
---@alias dm.StackFrameNode {children: dm.ScopesNode[], child_by_name: table<string, dm.ScopesNode>}
---@alias dm.ScopesTreeNode dm.VariablesNode | dm.ScopesNode | dm.StackFrameNode | dm.ScopesRoot

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

scopes.toggle_variables = function(node, event)
  local s = dap.session()
  node.collapsed = not node.collapsed
  if s and (node.variablesReference or -1) > 0 and not node.children then
    scopes.load_variables(s, node, function()
      node.collapsed = false
      event.view:refresh(node)
    end)
  else
    event.view:refresh(node)
  end
end

scopes.root_handler = dispatcher.new {
  render = function(node, event)
    event.out.lines = {
      { { "SCOPES:", "WarningMsg" }, },
      {
        { "1. Expand node - <CR> ",     "Comment" },
        { "2. Expand recursively - r ", "Comment" },
        { '3. Send to watches - a',     "Comment" },
      }
    }
  end,
  keymaps = {}
}

scopes.scope_handler = dispatcher.new {
  ---@param node dm.ScopesNode
  render = function(node, event)
    local icon = node.collapsed and " " or " "
    icon = node.variablesReference == 0 and "" or icon
    event.out.lines = {
      { { icon }, { node.name } },
    }
  end,
  keymaps = {
    ["<CR>"] = scopes.toggle_variables
  }
}

---@param node dm.VariablesNode
scopes.variable_render = function(node, event)
end

scopes.var_handler = dispatcher.new {
  ---@param node dm.VariablesNode
  render = function(node, event)
    local icon = node.collapsed and " " or " "
    icon = (not node.variablesReference or node.variablesReference == 0) and "" or icon
    local indent = string.rep(" ", event.depth)
    local lines = vim.split(node.value, "\n")
    event.out.lines = {
      { { indent }, { icon }, { node.name, "Exception" }, { " = " } }
    }
    if #lines == 1 then
      table.insert(event.out.lines[1], { node.value, scopes.types_to_hl_group[node.type] })
    else
      for _, line in ipairs(lines) do
        table.insert(event.out.lines, { { line, "Comment" } })
      end
    end
  end,
  ---@type table<string, fun(node: dm.VariablesNode, event: dm.TreeNodeEvent)>
  keymaps = {
    ["<CR>"] = scopes.toggle_variables,
    K = function(node, event)
      local buf = api.nvim_create_buf(false, true)
      api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(vim.inspect(node), "\n"))
      vim.treesitter.start(buf, "lua")
      view.popup.new { buf = buf }
    end,
    r = function(node, event)
      print("launch recurvie expand")
      scopes.expand_recursive(node, function()
        event.view:refresh(node)
        print("recursive expand finished")
      end, 500)
    end,
    d = function(node, event)
      local UiManager = require("debugmaster.managers.UiManager")
      UiManager.watches.remove(node)
      event.view:refresh(UiManager.watches.root)
    end,
    a = function(node, event)
      if node.evaluateName then
        local UiManager = require("debugmaster.managers.UiManager")
        UiManager.watches.add(node.evaluateName, function()
          event.view:refresh(UiManager.watches.root)
        end)
      else
        print("no evaluateName!")
      end
    end
  }
}

---@param node dm.VariablesNode
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
---@param target dm.VariablesNode | dm.ScopesNode
---@param cb fun()
function scopes.load_variables(s, target, cb)
  assert(target.variablesReference ~= 0, "variables refernece == 0. can't load variables!!")
  local req = { variablesReference = target.variablesReference }
  s:request("variables", req, function(err, result)
    assert(not err)
    target.children = {}
    target.child_by_name = {}
    -- NOTE: should consider deep copy?
    ---@type dm.VariablesNode[]
    local vars = result.variables
    for _, var in ipairs(vars) do
      var.handler = scopes.var_handler
      target.child_by_name[var.name] = var
      table.insert(target.children, var)
    end
    cb()
  end)
end

---Loads all scopes. Return frame  on done via cb
---@param s dap.Session
---@param frame dap.StackFrame
---@param cb fun(root: dm.StackFrameNode)
function scopes.fetch_frame(s, frame, cb)
  ---@type dm.StackFrameNode
  local root = { kind = "frame", children = {}, child_by_name = {} }
  ---@param err any
  ---@param result dap.ScopesResponse
  s:request("scopes", { frameId = frame.id }, function(err, result)
    assert(not err)
    ---@type dm.ScopesNode[]
    local scp = result.scopes
    local tasks = {}
    for _, scope in ipairs(scp) do
      scope.children = {}
      scope.handler = scopes.scope_handler
      scope.collapsed = scope.name ~= "Locals"
      table.insert(root.children, scope)
      root.child_by_name[scope.name] = scope
      table.insert(tasks, function(on_done)
        scopes.load_variables(s, scope, on_done)
      end)
    end

    async.await_all(tasks, function()
      cb(root)
    end)
  end)
end

---@param s dap.Session
---@param from dm.ScopesNode | dm.VariablesNode
---@param to dm.ScopesNode | dm.VariablesNode
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
    res.handler = scopes.var_handler
    cb(res)
  end)
end

---@param s dap.Session
---@param from dm.StackFrameNode
---@param to dm.StackFrameNode
---@param cb fun() on done
function scopes.sync_frame(s, from, to, cb)
  local tasks = {}

  for _, to_scope in ipairs(to.children) do
    local from_scope = from.child_by_name[to_scope.name]
    if from_scope then
      table.insert(tasks, function(on_done)
        scopes.sync_variables(s, from_scope, to_scope, on_done)
      end)
    end
  end
  async.await_all(tasks, cb)
end

return scopes
