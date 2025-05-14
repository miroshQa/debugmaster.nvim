local api = vim.api

local tree = {}

---@alias dm.HlSegment [string, string] First is text, second is highlight group.
---@alias dm.HlLine dm.HlSegment[]

---@class dm.RenderAdditional
---@field vlines dm.HlLine?

---@class dm.TreeNode
---@field expanded boolean?
---@field children dm.TreeNode[]?

---@class dm.TreeRenderSnapshot
---@field root dm.TreeNode
---@field len number
---@field buf number
---@field nodes_by_line table<number, dm.TreeNode>

---@alias dm.NodeRenderer fun(node: dm.TreeNode, depth: number, parent: dm.TreeNode?): dm.HlLine, dm.RenderAdditional?
---@class dm.TreeRenderParams
---@field buf number
---@field root dm.TreeNode
---@field renderer dm.NodeRenderer

---Render tree like structure conforming to the
---dm.TreeNode interface. Each node can contains expanded and children field
---interface (contract) doesn't require them to present
---in this case children are simply not rendered
---Returns the render snapshot, that can be used to retrieve node by line, etc
---@param opts dm.TreeRenderParams
---@return dm.TreeRenderSnapshot
function tree.render(opts)
  local lines = {}
  local highlights = {}      -- {line, hl_group, start_col, end_col}
  local virt_line_marks = {} -- {line = N, lines = virt_lines}
  local line_num = 0
  local nodes_by_line = {}
  local ns_id = api.nvim_create_namespace("")

  -- Build lines and text highlights specs
  ---@type fun(cur: dm.TreeNode, depth: number, parent: dm.TreeNode?)
  local function render_node(cur, depth, parent)
    local segments, additional = opts.renderer(cur, depth, parent)
    local line_text = ""
    local current_col = 0
    for _, seg in ipairs(segments) do
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

    if additional and additional.vlines and #additional.vlines > 0 then
      table.insert(virt_line_marks, { line = line_num, lines = additional.vlines })
    end

    table.insert(lines, line_text)
    nodes_by_line[line_num] = cur
    line_num = line_num + 1

    if cur.expanded and cur.children then
      for _, child in ipairs(cur.children) do
        render_node(child, depth + 1, cur)
      end
    end
  end
  render_node(opts.root, 0, nil)

  local buf = opts.buf
  api.nvim_set_option_value("modifiable", true, { buf = buf })
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = opts.buf })
  for _, h in ipairs(highlights) do
    api.nvim_buf_set_extmark(buf, ns_id, h.line, h.col_start, {
      end_col = h.col_end,
      hl_group = h.hl
    })
  end

  for _, mark in ipairs(virt_line_marks) do
    api.nvim_buf_set_extmark( buf, ns_id, mark.line, 0, {
        virt_lines = mark.lines,
        virt_lines_above = false,
      })
    end

  ---@type dm.TreeRenderSnapshot
  local snapshot = {
    root = opts.root,
    len = #lines,
    buf = opts.buf,
    nodes_by_line = nodes_by_line,
  }
  return snapshot
end

return tree
