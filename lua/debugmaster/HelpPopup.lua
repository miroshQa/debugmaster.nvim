local utils = require("debugmaster.utils")

local M = {}

---@class debugmaster.HelpPopup
local HelpPopup = {}

---@param groups dm.MappingsGroup[]
function M.new(groups)
  ---@class debugmaster.HelpPopup
  local self = setmetatable({}, { __index = HelpPopup })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.win = nil
  local lines = {}

  for _, group in ipairs(groups) do
    table.insert(lines, group.name)
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
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
  vim.api.nvim_buf_set_keymap(self.buf, "n", "q", "<cmd>q<CR>", {})

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
