local tree = require("debugmaster.lib.tree")
local api = vim.api


local dashboard = {}

---@class dm.DashboardComp
---@field node dm.TreeNode
---@field nodes_by_line table<number, dm.TreeNode>
---@field renderer dm.NodeRenderer
---@field handlers dm.TreeNodeHandler[]
---@field kind string

---@alias dm.DashboardRootNode {kind: "root", children: dm.DashboardComp[]}

---@type fun(comps: dm.DashboardComp[])
function dashboard.new(comps)
  ---@type dm.TreeNodeHandler[]
  local handlers = {
    {
      key = "<CR>",
      action = function(cur, tr)
      end
    }
  }

  ---@type dm.TreeNodeAction
  local handler = function(cur, tr)

  end

  ---@type dm.NodeRenderer
  ---@param node dm.DashboardComp
  local renderer = function(node, _, _)
    local all_lines = {}
    for cur, depth, parent in tree.iter(node.node) do
      local lines = node.renderer(cur, depth, parent) or {}
      for line in ipairs(lines) do
        table.insert(all_lines, line)
        node.nodes_by_line[#all_lines] = cur
      end
    end
    return all_lines
  end
end

return dashboard
