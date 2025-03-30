---@alias dm.HlLine [string, string] First is text, second is highlight group
---@alias dm.NodeRepr nil | dm.HlLine[]
---@alias dm.ChildrenIter fun(): dm.NodeTrait?

---@class dm.NodeTrait Supposedly it should be template parameter to Tree but since lua-ls doesn't support generic classes...
---@field id string
---@field is_expanded fun(self): boolean
---@field get_children_iter fun(self, depth): dm.ChildrenIter
---@field get_repr fun(self, depth): dm.NodeRepr


---@class dm.Tree
local Tree = {}

function Tree.new(buf, root)
  ---@class dm.Tree
  local self = setmetatable({}, { __index = Tree })
  self.buf = buf
  self.root = root
  self._nodes_by_line = {}
  self._nodes_by_id = {}
  self._ns_id = vim.api.nvim_create_namespace("")
  return self
end

function Tree.new_with_buf(root)
  return Tree.new(vim.api.nvim_create_buf(false, true), root)
end

function Tree:render(start)
  self._nodes_by_line = {}
  self._nodes_by_id = {}
  local lines = {}
  local highlights = {}      -- {line, hl_group, start_col, end_col}
  local virt_line_marks = {} -- {line = N, lines = virt_lines}
  local line_num = 0

  local function render_node(node, depth)
    -- Get both regular segments and virtual lines
    local segments, virtual_lines = node:get_repr(depth)
    segments = segments or {}

    -- Build line text and highlights
    local line_text = ""
    local current_col = 0
    for _, seg in ipairs(segments) do
      line_text = line_text .. seg[1]
      if seg[2] then
        table.insert(highlights, {
          line = line_num,
          hl = seg[2],
          start = current_col,
          ["end"] = current_col + #seg[1]
        })
      end
      current_col = current_col + #seg[1]
    end

    -- Record node and advance line number
    table.insert(lines, line_text)
    self._nodes_by_line[line_num] = node
    self._nodes_by_id[node.id] = node

    -- Store virtual lines if provided
    if virtual_lines and #virtual_lines > 0 then
      table.insert(virt_line_marks, {
        line = line_num,
        lines = virtual_lines
      })
    end

    line_num = line_num + 1

    -- Render children if expanded
    if node:is_expanded() then
      for child in node:get_children_iter(depth) do
        render_node(child, depth + 1)
      end
    end
  end

  render_node(self.root, 0)

  -- Update buffer
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(self.buf, self._ns_id, 0, -1)

  -- Apply syntax highlights
  for _, h in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      self.buf,
      self._ns_id,
      h.hl,
      h.line,
      h.start,
      h["end"]
    )
  end

  -- Add virtual lines using extmarks
  for _, mark in ipairs(virt_line_marks) do
    vim.api.nvim_buf_set_extmark(
      self.buf,
      self._ns_id,
      mark.line, -- 0-based line number
      0,         -- 0-based column
      {
        virt_lines = mark.lines,
        virt_lines_above = false,
      }
    )
  end
end

function Tree:node_by_line(linenr)
  return self._nodes_by_line[linenr]
end

function Tree:node_by_id(id)
  return self._nodes_by_id[id]
end

return Tree
