local dap = require("dap")
local view = require("debugmaster.components.generic.view")
local log = require("debugmaster.utils").log
local log_clear = require("debugmaster.utils").log_clear

local scopes = {}


---@class dm.ScopesNode: dap.Scope
---@field kind "scope"
---@field children dm.VariablesNode[]? no children means not loaded
---@field expanded boolean
---@field child_by_name table<string, dm.VariablesNode>

---@class dm.VariablesNode: dap.Variable
---@field kind "var"
---@field children dm.VariablesNode[]? no children means not loaded
---@field expanded boolean
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

---@param node dm.ScopesTreeNode
---@type dm.NodeRenderer
function scopes.render_node(node, depth)
  if node.kind == "scope" then
    return { { node.name } }
  elseif node.kind == "root" then
    return { { "Scopes:", "WarningMsg" }, { " Expand node - <CR>" }, { " K - inspect node" } }
  elseif node.kind == "var" then
    local indent = string.rep("  ", depth)
    return { { indent }, { node.name, "Exception" }, { " = " }, { node.value, scopes.types_to_hl_group[node.type] } }
  end
end

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
  to.expanded = from.expanded
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

---@class dm.ScopesTreeNodeHandler: dm.TreeNodeHandler
---@field action fun(cur: dm.ScopesTreeNode, tr: dm.Tree)

---@type dm.ScopesTreeNodeHandler[]
scopes.handlers = {
  {
    key = "<CR>",
    action = function(cur, tr)
      local s = dap.session()
      cur.expanded = not cur.expanded
      if s and cur.variablesReference > 0 and not cur.children then
        scopes.load_variables(s, cur, function()
          print("resolving reference")
          tr:refresh()
        end)
      else
        tr:refresh()
      end
    end
  },
  {
    key = "r",
    action = function(cur, tr)
      if cur.children then
        cur.expanded = not cur.expanded
      end
      local s = dap.session()
      if s and not cur.children then
        scopes.resolve_variables_recursive(s, cur, function()
          tr:refresh()
        end)
      else
        tr:refresh()
      end
    end
  },
  {
    key = "K",
    action = function(cur)
      local b = vim.api.nvim_create_buf(false, true)
      vim.keymap.set("n", "q", function()
        vim.cmd("q")
      end, { buffer = b })
      vim.bo[b].filetype = "lua"
      vim.api.nvim_buf_set_lines(b, 0, -1, false, vim.split(vim.inspect(cur), "\n"))
      view.new_float_anchored(b)
      cur.expanded = not cur.expanded
    end
  },
  {
    key = "s",
    action = function(cur, tr)
      vim.print(tr.snapshot.stats[cur])
    end
  }
}

scopes.comp = (function()
  local tree = require("debugmaster.components.generic.tree")
  local after = dap.listeners.after
  local before = dap.listeners.after
  local id = "debugmaster"

  local tr = tree.new({
    kind = "root",
    children = nil,
    expanded = true,
  }, { renderer = scopes.render_node, handlers = scopes.handlers })

  after.event_stopped[id] = function()
    local s = dap.session()
    if not s or not s.current_frame then
      return
    end
    scopes.fetch_frame(s, s.current_frame, function(to)
      if not tr.root.children then -- first init
        tr.root.children = { to }
        tr:refresh()
        return
      end
      local from = tr.root.children[1]
      log("from", from)
      log("to", to)
      scopes.sync_frame(s, from, to, function()
        log("to result ", to)
        tr.root.children = { to }
        tr:refresh()
      end)
    end)
  end

  return {
    name = "[S]copes",
    buf = tr.buf,
  }
end)()

return scopes
