---@class dm.debug.mode
local M = {}


local active = false
local groups = require("debugmaster.debug.keymaps").groups
local api = vim.api

---@class dm.OrignalKeymap
---@field callback function?
---@field rhs string?
---@field desc string?
---@field silent boolean?

---@type table<string, table<string, dm.OrignalKeymap>> [mode: {key: OriginalKeymap}, ...]
local originals = {}

local function save_original_settings()
  local all = {
    n = api.nvim_get_keymap("n"),
    v = api.nvim_get_keymap("v"),
  }
  local lhs_to_map = {}

  for mode, mappings in pairs(all) do
    lhs_to_map[mode] = {}
    for _, mapping in ipairs(mappings) do
      lhs_to_map[mode][mapping.lhs] = mapping
    end
  end

  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      for _, mode in ipairs(mapping.modes or { "n" }) do
        local key = mapping.key
        if not originals[mode] then
          originals[mode] = {}
        end
        local orig = lhs_to_map[mode][key] or {}
        originals[mode][key] = {
          callback = orig.callback,
          rhs = orig.rhs,
          desc = orig.desc,
          silent = orig.silent,
        }
      end
    end
  end
end

M.enable = (function()
  local is_first_enable = true
  return function()
    if is_first_enable then
      save_original_settings()
      is_first_enable = false
    end
    if active then
      return
    end
    active = true
    for _, group in ipairs(groups) do
      for _, mapping in ipairs(group.mappings) do
        local action = mapping.action
        for _, mode in ipairs(mapping.modes or { "n" }) do
          vim.keymap.set(mode, mapping.key, action, { nowait = mapping.nowait })
        end
      end
    end
    api.nvim_exec_autocmds("User", { pattern = "DebugModeChanged", data = { enabled = true } })
  end
end)()

function M.disable()
  if not active then
    return
  end
  active = false
  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local key = mapping.key
      for _, mode in ipairs(mapping.modes or { "n" }) do
        local orig = originals[mode][key]
        local rhs = orig.callback or orig.rhs or key
        vim.keymap.set(mode, key, rhs, {
          desc = orig.desc,
          silent = orig.silent,
        })
      end
    end
  end
  api.nvim_exec_autocmds("User", { pattern = "DebugModeChanged", data = { enabled = false } })
end

function M.toggle()
  (active and M.disable or M.enable)()
end

function M.is_active()
  return active
end

return M
