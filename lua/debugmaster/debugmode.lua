local M = {}

local config = require("debugmaster.config")

M.HelpPopup = require("debugmaster.HelpPopup").new(config.groups)

M.active = false
local groups = config.groups

---@class dm.OrignalKeymap
---@field callback function?
---@field rhs string?
---@field desc string?
---@field silent boolean?

---@type table<string, dm.OrignalKeymap>
local originals = {
}
local guicursor_original = nil

local function save_original_settings()
  local all = vim.api.nvim_get_keymap("n")
  local lhs_to_map = {}

  for _, mapping in ipairs(all) do
    lhs_to_map[mapping.lhs] = mapping
  end

  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local key = mapping.key
      originals[key] = {}
      local orig = lhs_to_map[key]
      if orig then
        originals[key].callback = orig.callback
        originals[key].rhs = orig.rhs
        originals[key].desc = orig.desc
        originals[key].silent = orig.silent
      end
    end
  end
  guicursor_original = vim.opt.guicursor._value
end
save_original_settings()

function M.activate()
  if M.active then
    return
  end
  M.active = true
  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local action = mapping.action
      vim.keymap.set("n", mapping.key, action, { nowait = mapping.nowait })
    end
  end

  guicursor_original = vim.opt.guicursor._value
  vim.api.nvim_set_hl(0, "dCursor", { bg = "#2da84f" })
  vim.opt.guicursor = "n-v-sm:block-dCursor,i-t-ci-ve-c:ver25,r-cr-o:hor20"
end

function M.disable()
  M.active = false
  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local key = mapping.key
      local orig = originals[key]
      local rhs = orig.callback or orig.rhs or key
      vim.keymap.set("n", key, rhs, {
        desc = orig.desc,
        silent = orig.silent,
      })
    end
  end
  vim.opt.guicursor = guicursor_original
end

function M.toggle()
  if M.active then
    M.disable()
  else
    M.activate()
  end
end

return M
