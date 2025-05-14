local api = vim.api
local tree = require("debugmaster.ui.tree")
-- need to rewrite it in the future, so scopse module didn't know about
-- dap at all, it absolutes isn't his responsibility. It just should accept data (scopes)
-- from some function like Scopes.render(scopes) and render it
local dap = require("dap")
local after = dap.listeners.after
local before = dap.listeners.before
local id = "debugmaster"

local Scopes = {}

function Scopes.new()
  ---@class dm.ui.Scopes: dm.ui.Sidepanel.IComponent
  local self = {}
  self.buf = vim.api.nvim_create_buf(false, true)
  self.name = "[S]copes"

  ---@class dm.ScopesNode: dap.Scope
  ---@field kind "scope"
  ---@field children dm.VariablesNode[]? no children means not loaded
  ---@field expanded boolean

  ---@class dm.VariablesNode: dap.Variable
  ---@field kind "var"
  ---@field children dm.VariablesNode[]? no children means not loaded
  ---@field expanded boolean

  ---@alias dm.ScopesDummyRoot {kind: "dummy", children: dm.ScopesNode[], expanded: true}
  ---@alias dm.ScopesTreeNode dm.VariablesNode | dm.ScopesNode | dm.ScopesDummyRoot

  ---@param node dm.ScopesTreeNode
  ---@type dm.NodeRenderer
  local function render_node(node, depth)
    if node.kind == "scope" then
      return { { node.name } }
    elseif node.kind == "var" then
      local indent = string.rep("  ", depth)
      return { { indent }, { node.name }, { " = " }, { node.value } }
    end
  end

  ---
  local function resolve_variables(parent, cb)
    local s = assert(dap.session())
    s:request("variables", { variablesReference = parent.variablesReference }, function(err, result)
      parent.children = {}
      for _, var in ipairs(result.variables) do
        var.kind = "var"
        table.insert(parent.children, var)
      end
      cb()
    end)
  end

  local function create_tree(cb)
    local s = assert(dap.session())
    local frame = s.current_frame
    if not frame then
      print("no frame")
      return
    end
    print("frame exist")

    ---@type dm.ScopesDummyRoot
    local root = { kind = "dummy", children = {}, expanded = true }
    ---@param err any
    ---@param result dap.ScopesResponse
    s:request("scopes", { frameId = frame.id }, function(err, result)
      local await_count = #result.scopes
      for _, scope in ipairs(result.scopes) do
        scope.kind = "scope"
        scope.children = {}
        scope.expanded = true
        table.insert(root.children, scope)
        resolve_variables(scope, function()
          await_count = await_count - 1
          if await_count == 0 then
            cb(root)
          end
        end)
      end
    end)
  end

  ---@type dm.TreeRenderSnapshot?
  local snapshot
  -- should move out it out of scopes after this draft
  -- widget should be resopnsible only for drawing and structure representing
  before.event_stopped[id] = function()
    create_tree(function(root)
      snapshot = tree.render { buf = self.buf, renderer = render_node, root = root }
    end)
  end


  vim.keymap.set("n", "<CR>", function()
    if not snapshot then return end
    local line = api.nvim_win_get_cursor(0)[1] - 1
    local cur = snapshot.nodes_by_line[line]
    if not cur then return end
    cur.expanded = not cur.expanded
    if not cur.children then
      resolve_variables(cur, function()
        -- TODO: Partial rendering
        snapshot = tree.render { buf = self.buf, renderer = render_node, root = snapshot.root }
      end)
    else
      snapshot = tree.render { buf = self.buf, renderer = render_node, root = snapshot.root }
    end
  end, { buffer = self.buf })

  api.nvim_create_autocmd("User", {
    pattern = "DapSessionChanged",
    callback = vim.schedule_wrap(function()
    end)
  })

  return self
end

return Scopes
