local utils = require("debugmaster.utils")

local M = {}

---@class debugmaster.HelpPopup
local HelpPopup = {}

---@param groups dm.MappingsGroup[]
function M.new(groups)
  ---@class debugmaster.HelpPopup
  local self = setmetatable({}, { __index = HelpPopup })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.hl_ns = vim.api.nvim_create_namespace("HelpPopupHighlightNamespace")
  self.win = nil
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
    vim.api.nvim_buf_add_highlight(self.buf, self.hl_ns, hl.hlgroup, hl.index, 0, -1)
  end


  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
  vim.api.nvim_buf_set_keymap(self.buf, "n", "q", "<cmd>q<CR>", {})
  vim.api.nvim_buf_create_user_command(self.buf, "CloseHelp", function ()
    self:close()
  end, {})
  vim.api.nvim_buf_set_keymap(self.buf, "n", "<esc>", "<cmd>CloseHelp<CR>", {})

  return self
end

function HelpPopup:open()
  if self.win and vim.api.nvim_buf_is_valid(self.win) then
    return
  end
  self.win = vim.api.nvim_open_win(self.buf, true, utils.make_center_float_win_cfg())
  vim.api.nvim_set_option_value("number", false, { win = self.win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = self.win })
  -- Auto close floating window if you accidentally click outside the window
  utils.register_to_close_on_leave(self.win)
end

function HelpPopup:close()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
end

return M
