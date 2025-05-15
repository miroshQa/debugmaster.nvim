local dap = require("dap")

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

return sessions
