local api = vim.api

local tree = {}

---@alias dm.HlSegment [string, string] First is text, second is highlight group.
---@alias dm.HlLine dm.HlSegment[]

---@class dm.WidgetRendererCtx Context
---@field parent dm.Widget
---@field depth integer

---@alias dm.WidgetRendererOut {lines: dm.HlLine[]}
---@alias dm.WidgetRenderer fun(self: dm.Widget, out: dm.WidgetRendererOut, parent: dm.Widget, depth: number)
---@alias dm.WidgetKeymapHandler fun(self: dm.Widget, view: dm.TreeView)

---@class dm.Widget
---@field render dm.WidgetRenderer?
---@field keymaps table<string, dm.WidgetKeymapHandler>?
---@field collapsed boolean?
---@field children dm.Widget[]?

---@class dm.SnapshotNodeInfo
---@field extmark_id number
---@field len number amount of lines including children
---@field depth number
---@field parent dm.Widget?

---@class dm.TreeRenderSnapshot
---@field buf number
---@field root dm.Widget
---@field extmarks_ns number
---@field node_by_extmark_id table<number, dm.Widget>
---@field nodes_info table<dm.Widget, dm.SnapshotNodeInfo>
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
  local node = self.node_by_extmark_id[mark[1]]
  assert(node, "No node under cursor! This could only happen if buffer was modified since render!")
  return node
end

---@class dm.TreeRenderParams
---@field buf number
---@field root dm.Widget
---@field start number? starts with 0 like in api.set_lines. 0 by default
---@field end_ number? like in api.set_lines. -1 by default
---@field depth number? starting depth
---@field parent dm.Widget? start parent for root
---@field base? dm.TreeRenderSnapshot base snapshot

---Render tree like structure conforming to the
---dm.TreeNode interface. Each node can contains children and collapsed fields
---interface (contract) doesn't require them to present
---in this case children are simply not rendered
---It traverse all nodes if it has children. You can prevent node for being traversed by setting collapsed = true
---Returns the render snapshot, that can be used to retrieve node by line, etc
---@param params dm.TreeRenderParams
---@return dm.TreeRenderSnapshot
function tree.render(params)
  local base = params.base or {}
  local buf = params.buf
  local start = params.start or 0
  local end_ = params.end_ or -1
  local result_lines = {}
  local line_num = start
  local highlights = {} ---@type {line: number, hl: string, col_start: number, col_end: number}[]
  local nodes_info = base.nodes_info or {} ---@type table<dm.Widget, dm.SnapshotNodeInfo>
  local marks = {} ---@type {node: dm.Widget, row: number, end_row: number}[]

  ---@param node dm.Widget
  local function render(node, depth, parent)
    local out = {}
    if node.render then
      node:render(out, parent, depth)
    end

    local node_start = line_num
    local lines = out.lines or {}
    nodes_info[node] = { depth = depth, len = 0, extmark_id = 0, parent = parent }
    if #lines ~= 0 then
      table.insert(marks, { node = node, row = line_num, end_row = line_num + #lines - 1 })
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

    if node.children and not node.collapsed then
      for _, child in ipairs(node.children) do
        render(child, depth + 1, node)
      end
    end

    nodes_info[node].len = line_num - node_start
  end

  render(params.root, params.depth or 0, params.parent)

  local hl_ns = api.nvim_create_namespace("")
  api.nvim_set_option_value("modifiable", true, { buf = buf })
  api.nvim_buf_set_lines(buf, start, end_, false, result_lines)
  api.nvim_set_option_value("modifiable", false, { buf = params.buf })
  for _, h in ipairs(highlights) do
    api.nvim_buf_set_extmark(buf, hl_ns, h.line, h.col_start, { end_col = h.col_end, hl_group = h.hl })
  end

  local extmarks_ns = base.extmarks_ns or api.nvim_create_namespace("")
  local node_by_extmark_id = base.node_by_extmark_id or {}
  for _, mark in ipairs(marks) do
    local id = api.nvim_buf_set_extmark(buf, extmarks_ns, mark.row, 0, {
      end_row = mark.end_row,
      end_right_gravity = true, -- when we remove lines before this mark, end shouldn't shift backward. that is relevant only when end_row == mark.row
    })
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
---@field root dm.Widget
---@field buf number
local TreeViewMethods = {}
---@private
TreeViewMethods.__index = TreeViewMethods

---Partial rerenders node
---@param node dm.Widget? self.root if nil
function TreeViewMethods:refresh(node)
  node = node or self.root
  local nodes_info = self.snapshot.nodes_info

  local node_info = nodes_info[node]
  local id = node_info.extmark_id
  -- if node extmark_id == 0 means there is no extmark for this node (render returned empty lines array) len == 0
  -- let's find first visible parent then
  while node_info.parent and id == 0 do
    node = node_info.parent
    node_info = nodes_info[node]
    id = node_info.extmark_id
  end

  --- means we didn't find visible parent or user requested to refresh root
  if node == self.root then
    self.snapshot = tree.render { root = node, buf = self.buf }
    return
  end

  local start = api.nvim_buf_get_extmark_by_id(self.buf, self.snapshot.extmarks_ns, id, {})[1]
  local len = node_info.len
  local end_ = start + len
  api.nvim_buf_clear_namespace(self.buf, self.snapshot.extmarks_ns, start, end_)
  tree.render {
    root = node,
    buf = self.buf,
    base = self.snapshot,
    depth = node_info.depth,
    parent = node_info.parent,
    start = start,
    end_ = end_,
  }
  local lines_diff = nodes_info[node].len - len
  if lines_diff ~= 0 then
    local parent = node_info.parent
    while parent do
      local parent_info = nodes_info[parent]
      parent_info.len = parent_info.len + lines_diff
      parent = nodes_info[parent].parent
    end
  end
end

---@class dm.TreeViewParams
---@field root dm.Widget
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
    snapshot = tree.render { buf = buf, root = params.root },
  }, TreeViewMethods)

  for _, key in pairs(keymaps) do
    local mode = "n"
    api.nvim_buf_set_keymap(buf, mode, key, "", {
      nowait = true,
      callback = function()
        local node = self.snapshot:get()
        if not node.keymaps or not node.keymaps[key] then
          return
        end
        node.keymaps[key](node, self)
      end
    })
  end
  return self
end

return tree
