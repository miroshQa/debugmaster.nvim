local dap = require("dap")
local view = require("debugmaster.lib.view")
local tree = require("debugmaster.lib.tree")
local dispatcher = tree.dispatcher

local scopes = {}


---@class dm.ScopesNode: dap.Scope
---@field kind "scope"
---@field children dm.VariablesNode[]? no children means not loaded
---@field collapsed boolean
---@field child_by_name table<string, dm.VariablesNode>

---@class dm.VariablesNode: dap.Variable
---@field kind "var"
---@field children dm.VariablesNode[]? no children means not loaded
---@field collapsed boolean
---@field child_by_name table<string, dm.VariablesNode>

---@alias dm.ScopesRoot {kind: "root", children: dm.StackFrameNode[], expanded: true}
---@alias dm.StackFrameNode {kind: "frame", children: dm.ScopesNode[], child_by_name: table<string, dm.ScopesNode>, expanded: true}
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

scopes.toggle_variables = function(event)
  ---@type dm.VariablesNode | dm.ScopesNode
  local cur = event.cur
  local s = dap.session()
  cur.collapsed = not cur.collapsed
  if s and cur.variablesReference > 0 and not cur.children then
    scopes.load_variables(s, cur, function()
      cur.collapsed = false
      event.view:refresh(cur)
    end)
  else
    event.view:refresh(cur)
  end
end

scopes.root_handler = dispatcher.new {
  render = function(event)
    event.out.lines = {
      { { "SCOPES:", "WarningMsg" }, },
      { { "Expand node - <CR>" } }
    }
  end,
  keymaps = {}
}

scopes.scope_handler = dispatcher.new {
  ---@class dm.ScopeNodeRenderEvent: dm.TreeNodeRenderEvent
  ---@field cur dm.ScopesNode
  ---@param event dm.ScopeNodeRenderEvent
  render = function(event)
    local cur = event.cur
    local icon = cur.collapsed and " " or " "
    icon = cur.variablesReference == 0 and "" or icon
    event.out.lines = {
      { { icon }, { cur.name } },
    }
  end,
  keymaps = {
    ["<CR>"] = scopes.toggle_variables
  }
}

scopes.var_handler = dispatcher.new {
  ---@class dm.VarsNodeRenderEvent: dm.TreeNodeRenderEvent
  ---@field cur dm.VariablesNode
  ---@param event dm.VarsNodeRenderEvent
  render = function(event)
    local node = event.cur
    local icon = node.collapsed and " " or " "
    icon = node.variablesReference == 0 and "" or icon
    local indent = string.rep("  ", event.depth)
    event.out.lines = {
      { { indent }, { icon }, { node.name, "Exception" }, { " = " }, { node.value, scopes.types_to_hl_group[node.type] } }
    }
  end,
  keymaps = {
    ["<CR>"] = scopes.toggle_variables,
  }
}

---Load varialles. Erase all previous children. Cb called on done. Set expanded = true
---@param s dap.Session
---@param target dm.VariablesNode | dm.ScopesNode
---@param cb fun()
function scopes.load_variables(s, target, cb)
  assert(target.variablesReference ~= 0, "variables refernece == 0. can't load variables!!")
  local req = { variablesReference = target.variablesReference }
  s:request("variables", req, function(err, result)
    target.children = {}
    target.child_by_name = {}
    -- NOTE: should consider deep copy?
    ---@type dm.VariablesNode[]
    local vars = result.variables
    for _, var in ipairs(vars) do
      var.kind = "var"
      var.handler = scopes.var_handler
      target.child_by_name[var.name] = var
      table.insert(target.children, var)
    end
    cb()
  end)
end

---Load varialles. Erase all previous children. Cb called on done
---This action pretty long time. Should add progress integration with fidget
---@param s dap.Session
---@param target dm.VariablesNode | dm.ScopesNode
---@param cb fun()
-- function scopes.resolve_variables_recursive(s, target, cb)
--   scopes.resolve_variables(s, target, function()
--     local await_count = #target.children
--     for _, child in ipairs(target.children) do
--       scopes.resolve_variables_recursive(s, child, function()
--         await_count = await_count - 1
--         if await_count == 0 then
--           cb()
--         end
--       end)
--     end
--   end)
-- end

---Loads all scopes. Return frame  on done via cb
---@param s dap.Session
---@param frame dap.StackFrame
---@param cb fun(root: dm.StackFrameNode)
function scopes.fetch_frame(s, frame, cb)
  ---@type dm.StackFrameNode
  local root = { kind = "frame", children = {}, expanded = true, child_by_name = {} }
  ---@param err any
  ---@param result dap.ScopesResponse
  s:request("scopes", { frameId = frame.id }, function(err, result)
    ---@type dm.ScopesNode[]
    local scp = result.scopes
    local await_count = #scp
    for _, scope in ipairs(scp) do
      scope.kind = "scope"
      scope.children = {}
      scope.handler = scopes.scope_handler
      scope.collapsed = scope.name ~= "Locals"
      table.insert(root.children, scope)
      root.child_by_name[scope.name] = scope
      scopes.load_variables(s, scope, function()
        await_count = await_count - 1
        if await_count == 0 then
          cb(root)
        end
      end)
    end
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
    local await_count = 0
    local cb_called = false
    for _, child_to in ipairs(to.children) do
      if from.child_by_name[child_to.name] then
        await_count = await_count + 1
      end
    end

    for _, child_to in ipairs(to.children) do
      local child_from = from.child_by_name[child_to.name]
      if child_from then
        scopes.sync_variables(s, child_from, child_to, function()
          await_count = await_count - 1
          if await_count == 0 and not cb_called then
            cb()
            cb_called = true
          end
        end)
      end
    end

    if await_count == 0 and not cb_called then
      cb()
      cb_called = true
    end
  end)
end

---@param s dap.Session
---@param from dm.StackFrameNode
---@param to dm.StackFrameNode
---@param cb fun() on done
function scopes.sync_frame(s, from, to, cb)
  local await_count = 0
  local cb_called = false
  for _, to_scope in ipairs(to.children) do
    if from.child_by_name[to_scope.name] then
      await_count = await_count + 1
    end
  end

  for _, to_scope in ipairs(to.children) do
    local from_scope = from.child_by_name[to_scope.name]
    if from_scope then
      scopes.sync_variables(s, from_scope, to_scope, function()
        await_count = await_count - 1
        if await_count == 0 and not cb_called then
          cb()
          cb_called = true
        end
      end)
    end
  end

  if await_count == 0 and not cb_called then
    cb()
    cb_called = true
  end
end

return scopes
