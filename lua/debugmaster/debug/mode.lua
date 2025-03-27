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
local originals = {
}

---@alias dm.debug.mode.callback fun(mode: dm.debug.mode)

---@type dm.debug.mode.callback[]
local callbacks = {}

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
end
save_original_settings()

function M.activate()
  if active then
    return
  end
  active = true
  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local action = mapping.action
      vim.keymap.set("n", mapping.key, action, { nowait = mapping.nowait })
    end
  end
  M._notify_all()
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
      vim.keymap.set("n", key, rhs, {
        desc = orig.desc,
        silent = orig.silent,
      })
    end
  end
  M._notify_all()
end

function M._notify_all()
  for _, listener in ipairs(callbacks) do
    listener(M)
  end
end

---@param callback dm.debug.mode.callback
function M.add_callback_on_change(callback)
  table.insert(callbacks, callback)
end

function M.toggle()
  if active then
    M.disable()
  else
    M.activate()
  end
end

function M.is_active()
  return active
end

local new_modes_when_cancel = {
  v = true,
  V = true,
  i = true,
}

vim.api.nvim_create_autocmd("ModeChanged", {
  callback = function(args)
    local modes = vim.split(args.match, ":")
    local old, new = modes[1], modes[2]
    if M.is_active() and new_modes_when_cancel[new] then
      local ui = require("debugmaster.state").sidepanel
      if not ui:is_focused() then
        M.disable()
      end
    end
  end
})

return M
