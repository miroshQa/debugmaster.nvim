local dap = require("dap")
local breakpoints = require("dap.breakpoints")
local tree = require("debugmaster.ui.tree")
local api = vim.api



---@class dm.ui.Breakpoints: dm.ui.Sidepanel.IComponent
local Breakpoints = {}

function Breakpoints.new()
  local self = {}
  self.name = "[B]points"
  self.buf = api.nvim_create_buf(false, true)
  -- TODO: figure out if lua_ls handle {kind = "dir", ...} or {kind = "file", ...} notation right.
  -- That would be blast. We can immitate rust enums then. (How in typescript)
  -- https://github.com/jrop/u.nvim/blob/v2/examples/filetree.lua
  -- But probably it doesn't work. Because lua_ls is a dog shit to be honest (compared to ts_ls)

  ---@alias dm.BpContainer {kind: "container", children: dm.Bp[], buf: number, expanded: boolean }
  ---@alias dm.Bp {kind: "bp", line: number, condition?: string, buf: number}
  ---@alias dm.BpDummyRoot {kind: "dummy"}
  ---@alias dm.BpTreeNode dm.BpContainer | dm.Bp

  ---@param node dm.BpTreeNode
  local function render_node(node)
    -- yeah {kind = "a"} or {kind = "b"} notation doesn't work indeed
    -- Please someone create good lsp server for lua please...
    if node.kind == "dummy" then
      local help = {
        { { "t - remove breakpoint or all breakpoints in the file", "Comment" } },
        { { "c - change breakpoint condition", "Comment" } }
      }
      return { { "Breakpoints", "Exception" } }, { vlines = help }
    elseif node.kind == "container" then
      local path = api.nvim_buf_get_name(node.buf)
      path = vim.fn.fnamemodify(path, ":.")
      return { { path, "Statement" } }
    else
      local vlines = nil
      local indent = "    "
      local linenr = node.line
      local line = vim.trim(api.nvim_buf_get_lines(node.buf, linenr - 1, linenr, false)[1])
      local text = string.format("%s %s %s", indent, linenr, line)
      local condition = node.condition
      if condition and condition ~= "" then
        vlines = { { { indent }, { "condition: ", "Comment" }, { node.condition } } }
      end
      return { { text } }, vlines
    end
  end

  local snapshot
  local function rerender_tree()
    ---@type dm.BpDummyRoot
    local root = {
      kind = "dummy",
      expanded = true,
      children = {},
    }
    for buf, bpoints in pairs(breakpoints.get()) do
      ---@type dm.Bp[]
      local children = {}
      for _, bp in ipairs(bpoints) do
        bp.buf = buf
        bp.kind = "bp"
        table.insert(children, bp)
      end
      ---@type dm.BpContainer
      local container = { children = children, expanded = true, buf = buf, kind = "container" }
      table.insert(root.children, container)
    end
    snapshot = tree.render { buf = self.buf, root = root, renderer = render_node }
  end
  rerender_tree()

  vim.keymap.set("n", "c", function()
    local line = api.nvim_win_get_cursor(0)[1] - 1
    ---@type dm.BpTreeNode
    local node = snapshot.nodes_by_line[line]
    if node.kind == "bp" then
      local condition = vim.fn.input({ default = node.condition or "" })
      breakpoints.set({ condition = condition }, node.buf, node.line)
      rerender_tree()
    end
  end, { buffer = self.buf, nowait = true })


  vim.keymap.set("n", "t", function()
    local line = api.nvim_win_get_cursor(0)[1] - 1
    ---@type dm.BpTreeNode
    local node = snapshot.nodes_by_line[line]
    if not node then
      return
    end
    if node.kind == "bp" then
      breakpoints.remove(node.buf, node.line)
      for _, session in pairs(dap.sessions()) do
        session:set_breakpoints(breakpoints.get(node.buf))
      end
    elseif node.kind == "container" then
      for _, bp in pairs(node.children) do
        breakpoints.remove(node.buf, bp.line)
        for _, session in pairs(dap.sessions()) do
          session:set_breakpoints(breakpoints.get(bp.buf))
        end
      end
    end
    rerender_tree()
  end, { buffer = self.buf, nowait = true })

  vim.keymap.set("n", "<CR>", function()
    local line = api.nvim_win_get_cursor(0)[1] - 1
    ---@type dm.BpTreeNode
    local node = snapshot.nodes_by_line[line]
    if node then
      if node.kind == "bp" then
        breakpoints.remove(node.buf, node.line)
        vim.cmd("q")
        vim.cmd("buffer " .. node.buf)
        vim.cmd("normal " .. node.line .. "G")
      end
    end
  end)

  dap.listeners.after.setBreakpoints["debugmaster"] = function()
    rerender_tree()
  end

  return self
end

return Breakpoints
