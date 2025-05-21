local api = vim.api

local tree = {}

---@alias dm.HlSegment [string, string] First is text, second is highlight group.
---@alias dm.HlLine dm.HlSegment[]

---@class dm.TreeNodeRenderEvent
---@field name "render"
---@field cur dm.TreeNode
---@field depth number
---@field parent dm.TreeNode
---@field out {lines: dm.HlLine[]?}

---@class dm.TreeNodeKeymapEvent
---@field name "keymap"
---@field cur dm.TreeNode
---@field key string
---@field view dm.TreeView
---@field out nil

---@alias dm.TreeNodeEvent
---| dm.TreeNodeRenderEvent
---| dm.TreeNodeKeymapEvent

---@alias dm.TreeNodeEventHandler fun(event: dm.TreeNodeEvent)

---@class dm.TreeNode
---@field handler dm.TreeNodeEventHandler?
---@field collapsed boolean?
---@field children dm.TreeNode[]?

---@class dm.SnapshotNodeInfo
---@field start number Starts with 1
---@field len number amount of lines including children
---@field this_len number len only of this node not including children
---@field parent dm.TreeNode?

---@class dm.TreeRenderSnapshot
---@field root dm.TreeNode
---@field start number Starts with 1
---@field len number amount of lines including children
---@field buf number
---@field nodes dm.TreeNode[] nodes[1] = first node in the buffer starting with the `start` line number
---@field info table<dm.TreeNode, dm.SnapshotNodeInfo>
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
  local cur = self.nodes[line]
  assert(cur, "No node under cursor! This could only happen if buffer was modified since render!")
  return cur
end

---@class dm.TreeRenderParams
---@field buf number
---@field root dm.TreeNode
---@field start number? starts with 0 like in api.set_lines. 0 by default
---@field end_ number? like in api.set_lines. -1 by default
---@field depth number? starting depth

---Render tree like structure conforming to the
---dm.TreeNode interface. Each node can contains children and collapsed fields
---interface (contract) doesn't require them to present
---in this case children are simply not rendered
---It traverse all nodes if it has children. You can prevent node for being traversed by setting collapsed = true
---Returns the render snapshot, that can be used to retrieve node by line, etc
---@param opts dm.TreeRenderParams
---@return dm.TreeRenderSnapshot
function tree.render(opts)
  local start = opts.start or 0
  local end_ = opts.end_ or -1
  local result_lines = {}
  local highlights = {} ---@type {line: number, hl: string, col_start: number, col_end: number}[]
  local line_num = start + 1
  local nodes = {} ---@type dm.TreeNode[]
  local info = {} ---@type table<dm.TreeNode, dm.SnapshotNodeInfo>
  local ns_id = api.nvim_create_namespace("")

  local function render(cur, depth, parent)
    ---@type dm.TreeNodeRenderEvent
    local event = { name = "render", cur = cur, depth = depth, parent = parent, out = {} }
    if cur.handler then
      cur.handler(event)
    end

    local lines = event.out.lines or {}
    info[cur] = { len = 0, start = line_num, parent = parent, this_len = #lines }
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
      table.insert(nodes, cur)
      line_num = line_num + 1
    end

    if cur.children and not cur.collapsed then
      for _, child in ipairs(cur.children) do
        render(child, depth + 1, cur)
      end
    end

    info[cur].len = line_num - info[cur].start
  end

  render(opts.root, opts.depth or 0, nil)

  local len = line_num - (start + 1)
  local buf = opts.buf
  if len ~= 0 then
    api.nvim_set_option_value("modifiable", true, { buf = buf })
    api.nvim_buf_set_lines(buf, start, end_, false, result_lines)
    api.nvim_set_option_value("modifiable", false, { buf = opts.buf })
    for _, h in ipairs(highlights) do
      api.nvim_buf_set_extmark(buf, ns_id, h.line - 1, h.col_start, {
        end_col = h.col_end,
        hl_group = h.hl
      })
    end
  end

  ---@type dm.TreeRenderSnapshot
  local snapshot = setmetatable({
    root = opts.root,
    start = start + 1,
    len = len,
    buf = opts.buf,
    nodes = nodes,
    info = info,
  }, SnapshotMethods)
  return snapshot
end

---@class dm.TreeView
---@field snapshot dm.TreeRenderSnapshot
---@field root dm.TreeNode
---@field buf number
local TreeViewMethods = {}
---@private
TreeViewMethods.__index = TreeViewMethods

---@param node dm.TreeNode?
function TreeViewMethods:refresh(node)
  if not node then
    self.snapshot = tree.render { buf = self.buf, root = self.root }
    return
  end

  -- PARTIAL RERENDERING IMPLEMENTATION
  local old_nodes = self.snapshot.nodes
  local line_num = 1
  local old_line_ptr = 1
  local nodes = {} ---@type dm.TreeNode[]
  local info = {} ---@type table<dm.TreeNode, dm.SnapshotNodeInfo>

  local function traverse(cur, depth, parent)
    info[cur] = { len = 0, start = line_num, parent = parent, this_len = 0 }
    if cur == node then
      local node_info = self.snapshot.info[node]
      local new_snapshot = tree.render {
        root = cur,
        buf = self.buf,
        start = node_info.start - 1,
        end_ = node_info.start - 1 + node_info.len,
        depth = depth,
      }
      info[cur].len = new_snapshot.len
      info[cur].this_len = new_snapshot.info[cur].this_len
      for _, new_node in ipairs(new_snapshot.nodes) do
        table.insert(nodes, new_node)
        line_num = line_num + 1
        info[new_node] = new_snapshot.info[new_node]
      end
    else
      local old_info = self.snapshot.info[cur]
      for _ = 1, old_info.this_len do
        table.insert(nodes, old_nodes[old_line_ptr])
        old_line_ptr = old_line_ptr + 1
        line_num = line_num + 1
      end
      info[cur].this_len = old_info.this_len
      if cur.children and not cur.collapsed then
        for _, child in ipairs(cur.children) do
          traverse(child, depth + 1, cur)
        end
      end
      info[cur].len = line_num - info[cur].start
    end
  end

  traverse(self.root, 0, nil)
  self.snapshot.len = line_num
  self.snapshot.nodes = nodes
  self.snapshot.info = info
end

---@class dm.TreeViewParams
---@field root dm.TreeNode
---@field keymaps string[]? Those keymaps will trigger keymap event for underlying cursor node

tree.view = {}
---@param params dm.TreeViewParams
function tree.view.new(params)
  local keymaps = params.keymaps or {}
  local buf = vim.api.nvim_create_buf(false, true)
  ---@type dm.TreeView
  local self = setmetatable({
    buf = buf,
    root = params.root,
    snapshot = tree.render({
      buf = buf,
      root = params.root,
    }),
  }, TreeViewMethods)

  for _, key in pairs(keymaps) do
    local mode = "n"
    api.nvim_buf_set_keymap(buf, mode, key, "", {
      callback = function()
        local cur = self.snapshot:cur()
        ---@type dm.TreeNodeKeymapEvent
        local event = { name = "keymap", cur = cur, key = key, view = self }
        cur.handler(event)
      end
    })
  end
  return self
end

tree.dispatcher = {}

---@class dm.TreeNodeEventDispatcherParams
---@field render fun(event: dm.TreeNodeRenderEvent)
---@field keymaps table<string, fun(event: dm.TreeNodeKeymapEvent)>

---@param params dm.TreeNodeEventDispatcherParams
---@return dm.TreeNodeEventHandler
function tree.dispatcher.new(params)
  return function(event)
    if event.name == "render" then
      params.render(event)
    elseif event.name == "keymap" then
      local handler = params.keymaps[event.key]
      if handler then
        handler(event)
      end
    end
  end
end

return tree
