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
---@field extmark_id number
---@field len number amount of lines including children
---@field depth number
---@field parent dm.TreeNode?

---@class dm.TreeRenderSnapshot
---@field buf number
---@field root dm.TreeNode
---@field extmarks_ns number
---@field node_by_extmark_id table<number, dm.TreeNode>
---@field nodes_info table<dm.TreeNode, dm.SnapshotNodeInfo>
local SnapshotMethods = {}
---@private
SnapshotMethods.__index = SnapshotMethods

---Convenience function. Extract current node under cursor
---Assume current window as cursor source by default (and currently the only option)
---Throw an error if current window buffer doesn't match snapshot buffer
---Throw an error if node doesn't exist. The only way it can happen if buffer was modified
---since snapshot creation. Hence you should track buffer changes by yourself
---and get rid of this snapshot if it happened
---@param line number? starts with 0
function SnapshotMethods:get(line)
  if not line then
    assert(self.buf == api.nvim_win_get_buf(0), "current window buf must match snapshot buf!")
    line = api.nvim_win_get_cursor(0)[1] - 1
  end
  local mark = api.nvim_buf_get_extmarks(self.buf, self.extmarks_ns, { line, 0 }, { line, 0 }, {
    limit = 1,
    overlap = true,
  })[1]
  assert(mark, "no mark!")
  local cur = self.node_by_extmark_id[mark[1]]
  assert(cur, "No node under cursor! This could only happen if buffer was modified since render!")
  return cur
end

---@class dm.TreeRenderParams
---@field buf number
---@field root dm.TreeNode
---@field start number? starts with 0 like in api.set_lines. 0 by default
---@field end_ number? like in api.set_lines. -1 by default
---@field depth number? starting depth
---@field parent dm.TreeNode? start parent for root

---Render tree like structure conforming to the
---dm.TreeNode interface. Each node can contains children and collapsed fields
---interface (contract) doesn't require them to present
---in this case children are simply not rendered
---It traverse all nodes if it has children. You can prevent node for being traversed by setting collapsed = true
---Returns the render snapshot, that can be used to retrieve node by line, etc
---@param params dm.TreeRenderParams
---@return dm.TreeRenderSnapshot
function tree.render(params)
  local buf = params.buf
  local start = params.start or 0
  local end_ = params.end_ or -1
  local result_lines = {}
  local line_num = start
  local highlights = {} ---@type {line: number, hl: string, col_start: number, col_end: number}[]
  local nodes_info = {} ---@type table<dm.TreeNode, dm.SnapshotNodeInfo>
  local marks = {} ---@type {node: dm.TreeNode, row: number, end_row: number}[]

  local function render(cur, depth, parent)
    ---@type dm.TreeNodeRenderEvent
    local event = { name = "render", cur = cur, depth = depth, parent = parent, out = {} }
    if cur.handler then
      cur.handler(event)
    end

    local node_start = line_num
    local lines = event.out.lines or {}
    nodes_info[cur] = { depth = depth, len = 0, extmark_id = 0, parent = parent }
    if #lines ~= 0 then
      table.insert(marks, { node = cur, row = line_num, end_row = line_num + #lines - 1 })
    end
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
      line_num = line_num + 1
    end

    if cur.children and not cur.collapsed then
      for _, child in ipairs(cur.children) do
        render(child, depth + 1, cur)
      end
    end

    nodes_info[cur].len = line_num - node_start
  end

  render(params.root, params.depth or 0, params.parent)

  local extmarks_ns = api.nvim_create_namespace("")
  local hl_ns = api.nvim_create_namespace("")
  api.nvim_set_option_value("modifiable", true, { buf = buf })
  api.nvim_buf_set_lines(buf, start, end_, false, result_lines)
  api.nvim_set_option_value("modifiable", false, { buf = params.buf })
  for _, h in ipairs(highlights) do
    api.nvim_buf_set_extmark(buf, hl_ns, h.line, h.col_start, {
      end_col = h.col_end,
      hl_group = h.hl
    })
  end

  local node_by_extmark_id = {}
  for _, mark in ipairs(marks) do
    local id = api.nvim_buf_set_extmark(buf, extmarks_ns, mark.row, 0, { end_row = mark.end_row })
    nodes_info[mark.node].extmark_id = id
    node_by_extmark_id[id] = mark.node
  end

  ---@type dm.TreeRenderSnapshot
  local snapshot = setmetatable({
    buf = params.buf,
    root = params.root,
    extmarks_ns = extmarks_ns,
    node_by_extmark_id = node_by_extmark_id,
    nodes_info = nodes_info,
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
  self.snapshot = tree.render { buf = self.buf, root = self.root }
end

---@class dm.TreeViewParams
---@field root dm.TreeNode
---@field keymaps string[] Those keymaps will trigger keymap event for underlying cursor node

tree.view = {}
---@param params dm.TreeViewParams
function tree.view.new(params)
  local keymaps = params.keymaps
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
        local cur = self.snapshot:get()
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
