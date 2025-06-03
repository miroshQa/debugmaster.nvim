local api = vim.api

local utils = {}

-- https://www.reddit.com/r/neovim/comments/tz6p7i/how_can_we_set_color_for_each_part_of_statusline/
---@return string
function utils.status_line_apply_hl(str, hlGroup)
  return "%#" .. hlGroup .. "#" .. str .. "%*"
end

function utils.get_windows_for_buffer(buf)
  local windows = {}
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_get_buf(win) == buf then
      table.insert(windows, win)
    end
  end
  return windows
end

---@param buf number
---@param mode string
---@param key string
---@return vim.api.keyset.get_keymap?
function utils.get_local_keymap(buf, mode, key)
  for _, spec in ipairs(api.nvim_buf_get_keymap(buf, mode)) do
    if spec.lhs == key then
      return spec
    end
  end
end

---Set window local keymap for the current buffer.
-- It will work only when this buffer openned in this window
---@param win number
---@param key string
---@param mode string
---@param callback fun()
function utils.set_local_buf_win_keymap(win, key, mode, callback)
  local buf = api.nvim_win_get_buf(win)
  local old = utils.get_local_keymap(buf, "n", "q")
  vim.keymap.set(mode, key, function()
    if api.nvim_get_current_win() == win then
      callback()
    elseif old and old.callback then
      old.callback()
    end
  end, { buffer = buf })
end

function utils.get_string_hl(str, lang)
  local query = assert(vim.treesitter.query.get(lang, "highlights"))
  local lang_tree = vim.treesitter.get_string_parser(str, lang)
  local ts_tree = lang_tree:parse()[1]

  local prev_r = 1
  local result = {}
  for i, n, _ in query:iter_captures(ts_tree:root(), str) do
    local cap = query.captures[i]
    local _, _, l, _, _, r = n:range(true)

    if prev_r <= l then
      table.insert(result, { str:sub(prev_r, l) })
    end
    table.insert(result, { str:sub(l + 1, r), ("@%s.%s"):format(cap, lang) })
    prev_r = r + 1
  end
  if prev_r <= #str then
    table.insert(result, { str:sub(prev_r) })
  end
  return result
end

function utils.clamp(n, low, high)
  return math.min(math.max(n, low), high)
end

function utils.get_file_icon()
end


---inspect with ignoreed property
function iinspect(obj, should_ignore)
  ---@type {cur: any, property: any, value: any}[]
  local removed = {}

  local function traverse(cur)
    for property, value in pairs(cur) do
      if should_ignore(property) then
        table.insert(removed, { cur = cur, property = property, value = value })
        cur[property] = nil
      elseif type(value) == "table" then
        traverse(value)
      end
    end
  end
  traverse(obj)
  local representation = vim.inspect(obj)
  for _, entry in ipairs(removed) do
    entry.cur[entry.property] = entry.value
  end
  return representation
end

local banned = {
  ["$__lldb_extensions"] = true,
  ["session"] = true,
  ["Globals"] = true,
  ["Registers"] = true,
}

function ignore(property)
  return banned[property] == true
end

function wtf(self, from, type)
  print(string.format("syncing self %s: %s"), type, iinspect(self, ignore))
  print("from %s: %s", type, iinspect(from, ignore))
end


return utils
