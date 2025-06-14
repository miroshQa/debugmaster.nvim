local api = vim.api

---@type dm.Canvas[]
local canvases = setmetatable({}, { __mode = "v" })

---@alias dm.HlSegment [string, string] First is text, second is highlight group.
---@alias dm.HlLine dm.HlSegment[]

---@class dm.WidgetRendererCtx Context
---@field parent dm.Widget
---@field depth integer

---@class dm.WidgetRendererOut
---@field lines dm.HlLine[]

---@alias dm.WidgetRenderer fun(self: dm.Widget, out: dm.WidgetRendererOut, parent: dm.Widget, depth: number)
---@alias dm.WidgetKeymapHandler fun(self: dm.Widget, canvas: dm.Canvas)

---@class dm.Widget
---@field render dm.WidgetRenderer?
---@field keymaps table<string, dm.WidgetKeymapHandler>?
---@field collapsed boolean?
---@field children dm.Widget[]?

---@class dm.RenderedWidgetInfo
---@field extmark_id number
---@field len number amount of lines including children
---@field depth number
---@field parent dm.Widget?

---@class dm.Canvas
---@field buf integer
---@field private hl_ns integer
---@field private extmarks_ns integer
---@field private node_by_extmark_id table<number, dm.Widget>
---@field package nodes_info table<dm.Widget, dm.RenderedWidgetInfo>
---@field private pushed_list dm.Widget[]
local Canvas = {}
---@private
Canvas.__index = Canvas

function Canvas.new()
  local self = setmetatable({
    buf = api.nvim_create_buf(false, true),
    extmarks_ns = api.nvim_create_namespace(""),
    hl_ns = api.nvim_create_namespace(""),
    node_by_extmark_id = {},
    nodes_info = {},
    pushed_list = {},
  }, Canvas)
  table.insert(canvases, self)
  return self
end

---@param widget dm.Widget
function Canvas.notify_about_change(widget)
  for _, canvas in ipairs(canvases) do
    if canvas.nodes_info[widget] then
      canvas:refresh(widget)
    end
  end
end

---Extract node attached to the line
---Throw an error if node doesn't exist. The only way it can happen if buffer was modified
---since canvas creation. Hence you should track buffer changes by yourself
---and get rid of this canvas if it happened
---@param line integer? starts with 0
function Canvas:get(line)
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
---@field root dm.Widget
---@field start number? starts with 0 like in api.set_lines. 0 by default
---@field end_ number? like in api.set_lines. -1 by default
---@field depth number? starting depth
---@field parent dm.Widget? start parent for root

---Render tree like structure conforming to the
---dm.TreeNode interface. Each node can contains children and collapsed fields
---interface (contract) doesn't require them to present
---in this case children are simply not rendered
---It traverse all nodes if it has children. You can prevent node for being traversed by setting collapsed = true
---Returns the render snapshot, that can be used to retrieve node by line, etc
---@param params dm.TreeRenderParams
function Canvas:_render(params)
  local buf = self.buf
  local start = params.start or 0
  local end_ = params.end_ or -1
  local result_lines = {}
  local line_num = start
  local highlights = {} ---@type {line: number, hl: string, col_start: number, col_end: number}[]
  local marks = {} ---@type {node: dm.Widget, row: number, end_row: number}[]

  ---@param node dm.Widget
  local function render(node, depth, parent)
    local out = {}
    if node.render then
      node:render(out, parent, depth)
    end

    local node_start = line_num
    local lines = out.lines or {}
    self.nodes_info[node] = { depth = depth, len = 0, extmark_id = 0, parent = parent }
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
          local col_end = current_col + #seg_text
          table.insert(highlights, { line = line_num, hl = seg[2], col_start = current_col, col_end = col_end })
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

    self.nodes_info[node].len = line_num - node_start
  end

  render(params.root, params.depth or 0, params.parent)

  api.nvim_set_option_value("modifiable", true, { buf = buf })
  api.nvim_buf_set_lines(buf, start, end_, false, result_lines)
  api.nvim_set_option_value("modifiable", false, { buf = buf })
  for _, h in ipairs(highlights) do
    api.nvim_buf_set_extmark(buf, self.hl_ns, h.line, h.col_start, { end_col = h.col_end, hl_group = h.hl })
  end

  local node_by_extmark_id = self.node_by_extmark_id or {}
  for _, mark in ipairs(marks) do
    local id = api.nvim_buf_set_extmark(buf, self.extmarks_ns, mark.row, 0, {
      end_row = mark.end_row,
      end_right_gravity = true, -- when we remove lines before this mark, end shouldn't shift backward. that is relevant only when end_row == mark.row
    })
    self.nodes_info[mark.node].extmark_id = id
    node_by_extmark_id[id] = mark.node
  end
end

---@param node dm.Widget?
function Canvas:refresh(node)
  local nodes_info = self.nodes_info
  -- let's find node with extmark_id ~= 0 that means this node was rendered and is on the canvas (len ~= 0)
  -- find first visible parrent if passed node has len == 0
  local node_info ---@type dm.RenderedWidgetInfo
  local id ---@type integer
  while node do
    node_info = nodes_info[node]
    id = node_info.extmark_id
    if id ~= 0 then
      break
    end
    node = node_info.parent
  end

  --- means we didn't find visible parent, then we refresh all canvas
  if not node then
    local pushed_list = self.pushed_list
    local cursor = api.nvim_win_get_cursor(0)
    self:clear()
    for _, widget in ipairs(pushed_list) do
      self:push(widget)
    end
    api.nvim_win_set_cursor(0, cursor)
    return
  end

  local start = api.nvim_buf_get_extmark_by_id(self.buf, self.extmarks_ns, id, {})[1]
  local len = node_info.len
  local end_ = start + len
  api.nvim_buf_clear_namespace(self.buf, self.extmarks_ns, start, end_)
  self:_render {
    root = node,
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

function Canvas:push(widget)
  local line_count = api.nvim_buf_line_count(self.buf)
  local is_clean_buf = line_count == 1 and api.nvim_buf_get_lines(self.buf, 0, -1, true)[1] == ""
  local start = is_clean_buf and line_count - 1 or line_count
  self:_render { start = start, root = widget }
  table.insert(self.pushed_list, widget)
end

function Canvas:clear()
  self.pushed_list = {}
  self.nodes_info = {}
  self.node_by_extmark_id = {}
  api.nvim_set_option_value("modifiable", true, { buf = self.buf })
  api.nvim_buf_set_lines(self.buf, 0, -1, false, {})
  api.nvim_set_option_value("modifiable", false, { buf = self.buf })
end

---@param keymaps string[] Those keymaps will trigger keymap event for underlying cursor node
function Canvas:add_key_events(keymaps)
  for _, key in pairs(keymaps) do
    local mode = "n"
    api.nvim_buf_set_keymap(self.buf, mode, key, "", {
      nowait = true,
      callback = function()
        assert(self.buf == api.nvim_win_get_buf(0), "current window buf must match snapshot buf!")
        local line = api.nvim_win_get_cursor(0)[1] - 1
        local node = self:get(line)
        if not node.keymaps or not node.keymaps[key] then
          return
        end
        node.keymaps[key](node, self)
      end
    })
  end
end

local builtins = {
  ---@type dm.WidgetRenderer
  after_render_add_indent = function(self, out, parent, depth)
    if out.lines and depth ~= 0 then
      local indent = string.rep("  ", depth)
      for _, line in ipairs(out.lines) do
        table.insert(line, 1, { { indent } })
      end
    end
  end
}

return {
  Canvas = Canvas,
}
