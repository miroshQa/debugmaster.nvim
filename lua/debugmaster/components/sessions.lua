local dap = require("dap")
local tree = require("debugmaster.components.generic.tree")

local sessions = {}


---@alias dm.SessionDummyNode {kind: "dummy", children: dm.SessionNode[], expanded: boolean}
---@alias dm.SessionNode {session: dap.Session}
---@alias dm.SessionTreeNode dm.SessionNode | dm.SessionDummyNode

---@type dm.NodeRenderer
---@param node dm.SessionTreeNode
function sessions.render_node(node)
  if node.kind == "dummy" then
    return { { "Sessions:" } }
  else
    return { { "  " }, { tostring(node.session.id) }, { node.session.config.name } }
  end
end

---comment
---@return dm.SessionDummyNode
function sessions.build_tree()
  ---@type dm.SessionDummyNode
  local root = { kind = "dummy", children = {}, expanded = true }
  for _, s in pairs(dap.sessions()) do
    table.insert(root.children, {
      session = s,
    })
  end

  return root
end

sessions.comp = (function()
  local sessions_tree = tree.new(
    sessions.build_tree(),
    {renderer = sessions.render_node}
  )
  return {
    name = "Sessions",
    buf = sessions_tree.buf
  }
end)()
return sessions
