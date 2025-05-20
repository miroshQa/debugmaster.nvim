local dap = require("dap")
local tree = require("debugmaster.lib.tree")

local sessions = {}


---@alias dm.SessionDummyNode {kind: "dummy", children: dm.SessionNode[], expanded: boolean}
---@alias dm.SessionNode {kind: "session", session: dap.Session}
---@alias dm.SessionTreeNode dm.SessionNode | dm.SessionDummyNode

sessions.renderer = tree.dispatcher.renderer.new {
  dummy = function(node, depth, parent)
    return {
      { { "Sessions:" } },
    }
  end,
  ---@param node dm.SessionNode
  session = function(node, depth, parent)
    return {
      { { "  " }, { tostring(node.session.id) }, { node.session.config.name } },
    }
  end
}

---comment
---@return dm.SessionDummyNode
function sessions.build_tree()
  ---@type dm.SessionDummyNode
  local root = { kind = "dummy", children = {}, expanded = true }
  for _, s in pairs(dap.sessions()) do
    table.insert(root.children, {
      session = s,
      kind = "session",
    })
  end

  return root
end

---@type table<string, dm.TreeNodeAction>
sessions.actions = {
  ["<CR>"] = tree.dispatcher.action.new {
    ---@param cur dm.SessionNode
    session = function(cur, tr)
      print("session switching isn't implemented yet")
    end
  }
}

return sessions
