--TODO: Rewrite using tree

local api = vim.api
local help = {}


---comment
---@param groups any
---@return number buf number
function help.construct(groups)
  --TODO: rewrite it using tree
  local buf = api.nvim_create_buf(false, true)
  local hl_ns = api.nvim_create_namespace("HelpPopupHighlightNamespace")
  local lines = {}
  ---@type {index: number, hlgroup: string}[]
  local highlights = {}

  for _, group in ipairs(groups) do
    if group.name then
      table.insert(highlights, { index = #lines, hlgroup = group.hlgroup })
      table.insert(lines, group.name)
    end
    for _, spec in ipairs(group.mappings) do
      if spec.desc then
        local key = spec.key
        local indent = string.rep(" ", 10 - #key)
        table.insert(lines, string.format("%s %s  %s", key, indent, spec.desc))
      end
    end
    table.insert(lines, "")
  end

  table.remove(lines)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _, hl in ipairs(highlights) do
    api.nvim_buf_add_highlight(buf, hl_ns, hl.hlgroup, hl.index, 0, -1)
  end
  api.nvim_set_option_value("modifiable", false, { buf = buf })
  return buf
end

return help
