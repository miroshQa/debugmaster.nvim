local config = require("debugmaster.config")

---@class dm.debug.mode
local M = {}


local active = false
local groups = require("debugmaster.debug.keymaps").groups

---@class dm.OrignalKeymap
---@field callback function?
---@field rhs string?
---@field desc string?
---@field silent boolean?

---@type table<string, dm.OrignalKeymap>
local originals = {}

local function save_original_settings()
  local all = vim.api.nvim_get_keymap("n")
  local lhs_to_map = {}

  for _, mapping in ipairs(all) do
    lhs_to_map[mapping.lhs] = mapping
  end

  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local mode = mapping.mode or "n"
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
end
save_original_settings()

function M.enable()
  if active then
    return
  end
  active = true
  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local action = mapping.action
      local mode = mapping.mode or "n"
      vim.keymap.set(mode, mapping.key, action, { nowait = mapping.nowait })
    end
  end
  vim.api.nvim_exec_autocmds("User", { pattern = "DebugModeChanged", data = { enabled = true } })
end

function M.disable()
  if not active then
    return
  end
  active = false
  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local key = mapping.key
      local orig = originals[key]
      local rhs = orig.callback or orig.rhs or key
      local mode = mapping.mode or "n"
      vim.keymap.set("n", key, rhs, {
        desc = orig.desc,
        silent = orig.silent,
      })
    end
  end
  vim.api.nvim_exec_autocmds("User", { pattern = "DebugModeChanged", data = { enabled = false } })
end

function M.toggle()
  (active and M.disable or M.enable)()
end

function M.is_active()
  return active
end

return M
