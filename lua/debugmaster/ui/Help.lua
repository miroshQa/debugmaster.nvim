local utils = require("debugmaster.utils")

---@class debugmaster.ui.Help: debugmaster.ui.Sidepanel.IComponent
local Help = {}

---@param groups dm.MappingsGroup[]
function Help.new(groups)
  ---@class debugmaster.ui.Help
  local self = setmetatable({}, { __index = Help })
  self.buf = vim.api.nvim_create_buf(false, true)
  self._hl_ns = vim.api.nvim_create_namespace("HelpPopupHighlightNamespace")
  self.win = nil
  self.name = "[H]elp"
  local lines = {}
  ---@type {index: number, hlgroup: string}[]
  local highlights = {}

  for _, group in ipairs(groups) do
    if group.name then
      table.insert(highlights, {index = #lines, hlgroup = group.hlgroup})
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
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(self.buf, self._hl_ns, hl.hlgroup, hl.index, 0, -1)
  end
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
  return self
end

return Help
