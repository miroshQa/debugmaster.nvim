local M = {}

local dap = require("dap")
local config = require("debugmaster.config")

M.HelpPopup = require("debugmaster.HelpPopup").new(config.mappings)

M.active = false
local mappings = config.mappings

---@class dm.OrignalKeymap
---@field callback function?
---@field rhs string?
---@field desc string?

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

  for _, mapping in pairs(mappings) do
    local key = mapping.key
    originals[key] = {}
    local orig = lhs_to_map[key]
    if orig then
     originals[key].callback = orig.callback
     originals[key].rhs = orig.rhs
     originals[key].desc = orig.desc
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
  for _, mapping in pairs(mappings) do
    local action = mapping.action
    vim.keymap.set("n", mapping.key, action)
  end

  guicursor_original = vim.opt.guicursor._value
  vim.api.nvim_set_hl(0, "dCursor", { bg = "#2da84f"})
  vim.opt.guicursor = "n-v-c-sm:block-dCursor,i-t-ci-ve:ver25,r-cr-o:hor20"
end

function M.disable()
  M.active = false
  for _, mapping in pairs(mappings) do
    local key = mapping.key
    local orig = originals[key]
    local rhs = orig.callback or orig.rhs or key
    vim.keymap.set("n", key, rhs, {desc = orig.desc})
  end
  vim.opt.guicursor = guicursor_original
end

return M
