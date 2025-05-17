--TODO: Partial rendering. We already have stats for this
-- Need to develop this idea further

local api = vim.api

local tree = {}

---@alias dm.HlSegment [string, string] First is text, second is highlight group.
---@alias dm.HlLine dm.HlSegment[]

---@class dm.TreeNode
---@field collapsed boolean?
---@field children dm.TreeNode[]?

---@class dm.NodeRenderStat
---@field start number Start line number
---@field len number render len. end = start + len

---@class dm.TreeRenderSnapshot
---@field root dm.TreeNode
---@field len number
---@field buf number
---@field nodes_by_line table<number, dm.TreeNode> Starts with 1!
---@field stats table<dm.TreeNode, dm.NodeRenderStat>
local SnapshotMethods = {}
---@private
SnapshotMethods.__index = SnapshotMethods

---Convenience function. Extract current node under cursor
---Assume current window as cursor source by default (and currently the only option)
---Throw an error if current window buffer doesn't match snapshot buffer
---Throw an error if node doesn't exist. The only way it can happen if buffer was modified
---since snapshot creation. Hence you should track buffer changes by yourself
---and get rid of this snapshot if it happened
function SnapshotMethods:cur()
  assert(self.buf == api.nvim_win_get_buf(0), "current window buf must match snapshot buf!")
  local line = api.nvim_win_get_cursor(0)[1]
  local cur = self.nodes_by_line[line]
  assert(cur, "No node under cursor! This could only happen if buffer was modified since render!")
  return cur
end

---@alias dm.NodeRenderOutput nil | dm.HlLine[]

---parent must be null only for root element, depth starts with 0
---@alias dm.NodeRenderer fun(node: dm.TreeNode, depth: number, parent: dm.TreeNode?): dm.NodeRenderOutput

---@class dm.TreeRenderParams
---@field buf number
---@field root dm.TreeNode
---@field renderer dm.NodeRenderer

---Render tree like structure conforming to the
---dm.TreeNode interface. Each node can contains children and collapsed fields
---interface (contract) doesn't require them to present
---in this case children are simply not rendered
---By default use tree.iter. It traverse all nodes if it has children. You can prevent node for
---being traversed by setting collapsed = true
---Returns the render snapshot, that can be used to retrieve node by line, etc
---@param opts dm.TreeRenderParams
---@return dm.TreeRenderSnapshot
function tree.render(opts)
  local result_lines = {}
  ---@type {line: number, hl: string, col_start: number, col_end: number}[]
  local highlights = {}
  local line_num = 1
  local nodes_by_line = {}
  ---@type table<dm.TreeNode, dm.NodeRenderStat>
  local stats = {}

  local ns_id = api.nvim_create_namespace("")

  for cur, depth, parent in tree.iter(opts.root) do
    stats[cur] = { len = 0, start = line_num }
    ---@type dm.HlLine[]
    local lines = opts.renderer(cur, depth, parent) or {}

    for _, line in ipairs(lines) do
      local line_text = ""
      local current_col = 0
      for _, seg in ipairs(line) do
        local seg_text = seg[1]
        line_text = line_text .. seg_text
        if seg[2] then
          table.insert(highlights, {
            line = line_num,
            hl = seg[2],
            col_start = current_col,
            col_end = current_col + #seg_text
          })
        end
        current_col = current_col + #seg_text
      end

      table.insert(result_lines, line_text)
      nodes_by_line[line_num] = cur
      stats[cur].len = stats[cur].len + 1
      if parent then
        stats[parent].len = stats[parent].len + 1
      end
      line_num = line_num + 1
    end
  end


  local buf = opts.buf
  api.nvim_set_option_value("modifiable", true, { buf = buf })
  api.nvim_buf_set_lines(buf, 0, -1, false, result_lines)
  api.nvim_set_option_value("modifiable", false, { buf = opts.buf })
  for _, h in ipairs(highlights) do
    api.nvim_buf_set_extmark(buf, ns_id, h.line - 1, h.col_start, {
      end_col = h.col_end,
      hl_group = h.hl
    })
  end

  ---@type dm.TreeRenderSnapshot
  local snapshot = setmetatable({
    root = opts.root,
    len = #result_lines,
    buf = opts.buf,
    nodes_by_line = nodes_by_line,
    stats = stats,
  }, SnapshotMethods)
  return snapshot
end

---parent must be nil only for a root element. Depth starts with 0
---@alias dm.TreeIterator fun(): cur: dm.TreeNode, depth: number, parent: dm.TreeNode?

---construct iterator over tree like structure
---@param root dm.TreeNode Iteration starts with this node
---@return dm.TreeIterator
function tree.iter(root)
  return coroutine.wrap(function()
    ---@type fun(cur: dm.TreeNode, depth: number, parent: dm.TreeNode?)
    local function traverse(cur, depth, parent)
      coroutine.yield(cur, depth, parent)
      local should_traverse_children = cur.children and not cur.collapsed
      if should_traverse_children then
        for _, child in ipairs(cur.children) do
          traverse(child, depth + 1, cur)
        end
      end
    end
    traverse(root, 0, nil)
  end)
end

---@class dm.Tree
---@field root dm.TreeNode
---@field buf number
---@field snapshot dm.TreeRenderSnapshot Last render snapshot of the tree
---@field private _renderer dm.NodeRenderer
local TreeMethods = {}
---@private
TreeMethods.__index = TreeMethods

--- Refresh the node in the tree. By default root node is assumed
---TODO: return new snapshot? Override existing snapshot with old??? For partial rendering
---@param node dm.TreeNode?
function TreeMethods:refresh(node)
  self.snapshot = tree.render({
    buf = self.buf,
    root = node or self.root,
    renderer = self._renderer,
  })
end

---@alias dm.TreeNodeAction fun(cur: dm.TreeNode, tr: dm.Tree)


---@class dm.NewTreeParams
---@field root dm.TreeNode
---@field renderer dm.NodeRenderer
---@field handlers? table<string, dm.TreeNodeAction> key: node action. only normal mode yet. support for others will be added in the future

---Return more highlevel primitive than TreeSnapshot. You can live without it
---Implicitly creates tree snapshot
---@param params dm.NewTreeParams
---@return dm.Tree
function tree.new(params)
  local root = params.root
  local buf = vim.api.nvim_create_buf(false, true)
  local renderer = params.renderer
  local self = setmetatable({
    buf = buf,
    root = root,
    snapshot = tree.render({ buf = buf, root = root, renderer = renderer }),
    _renderer = renderer,
  }, TreeMethods)

  if params.handlers then
    for key, handler in pairs(params.handlers) do
      local mode = "n"
      api.nvim_buf_set_keymap(buf, mode, key, "", {
        callback = function()
          handler(self.snapshot:cur(), self)
        end
      })
    end
  end
  return self
end

---@class dm.NodeWithKind: dm.TreeNode
---@field kind string

tree.dispatcher = { action = {}, renderer = {} }

---handler also can be a string, will be used as alias on the other handler in this table
---@param handlers table<string, dm.NodeRenderer | string>
---@return dm.NodeRenderer
function tree.dispatcher.renderer.new(handlers)
  ---@type dm.NodeRenderer
  ---@param node  dm.NodeWithKind
  return function(node, depth, parent)
    assert(node.kind, "node must have kind!")
    local handler = handlers[node.kind]
    handler = type(handler) == "string" and handlers[handler] or handler
    if handler then return handler(node, depth, parent) else return nil end
  end
end

---handler also can be a string, will be used as alias on the other handler in this table
---@param handlers table<string, dm.TreeNodeAction | string>
---@return dm.TreeNodeAction
function tree.dispatcher.action.new(handlers)
  ---@type dm.TreeNodeAction
  ---@param node  dm.NodeWithKind
  return function(node, tr)
    assert(node.kind, "node must have kind!")
    local handler = handlers[node.kind]
    handler = type(handler) == "string" and handlers[handler] or handler
    if handler then return handler(node, tr) else return end
  end
end

-- need to duplicate this logic, otherwise we will lost up lua_ls diagnostic
-- https://luals.github.io/wiki/annotations/ need to wait when @overload issue will be resolved

-- Despite lua_ls lacks generic classes this tree implemenation play very well with types diagnostic
-- See scopes implementation. For each handler we just override desired node using @param

-- TODO: Add tree.loader component?

return tree
