---@class debugmaster.debug.mode
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
local guicursor_orig = vim.opt.guicursor._value
local cursorline_orig = vim.o.cursorline
local cursorline_bg_orig = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("CursorLine")), "bg")
-- TODO: I guess CursorLineNr also would be cool
local cursorline_au_id = nil

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

local last_entered_win = 0
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

  -- we want to see cursor line only in the current split
  -- TODO: Open PR in neovim repo. Because this basic feature should be in the core
  -- Add new hl group CursorLineInactive
  cursorline_au_id = vim.api.nvim_create_autocmd("WinEnter", {
    callback = function(args)
      if vim.api.nvim_win_is_valid(last_entered_win) then
        -- see :help vim.wo
        vim.wo[last_entered_win].cursorline = false
      end
      last_entered_win = vim.api.nvim_get_current_win()
      vim.wo.cursorline = true
    end
  })

  -- NOTES: Trying to undestand all those b, bo,g, go, opt, o, wo, ...
  --- Basically we have two entities: variables, options
  --- Options has "o" at the end.
  --- So vim.b - is buffer scoped variables, vim.g - global variables
  --- vim.bo - is buffer scoped OPTIONS, vim.go - global options
  --- what the hell is vim.opt then?
  last_entered_win = vim.api.nvim_get_current_win()
  vim.wo.cursorline = true
  vim.api.nvim_set_hl(0, "CursorLine", {bg = "#2c4e28"})
  vim.api.nvim_set_hl(0, "dCursor", { bg = "#2da84f" })
  vim.go.guicursor = "n-v-sm:block-dCursor,i-t-ci-ve-c:ver25,r-cr-o:hor20"
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
  vim.wo[0].cursorline = cursorline_orig
  vim.api.nvim_set_hl(0, "CursorLine", {bg = cursorline_bg_orig})
  vim.go.guicursor = guicursor_orig
  if cursorline_au_id then
    vim.api.nvim_del_autocmd(cursorline_au_id)
  end
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
      M.disable()
    end
  end
})

return M
