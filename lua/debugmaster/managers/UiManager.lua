-- UiController and access for each its element provider
local dap = require("dap")
local after = dap.listeners.after
local tree = require("debugmaster.lib.tree")
local SessionsManager = require("debugmaster.managers.SessionsManager")
local api = vim.api

---@class d.UiManagerComp
---@field name string
---@field buf number

local UiManager = {}

UiManager.terminal = (function()
  local _dummy_buf = api.nvim_create_buf(false, true)
  local comp = {
    name = "[T]erminal",
    buf = _dummy_buf,
  }

  local lines = {
    "Debug adapter didn't provide term",
    "1. Either no session is active",
    "2. Eiter you attached to the process",
    "And then you can move the neovim term with the program",
    "to this section using 'dm' keymap in the debug mode",
    "3. Either you need to tweak your adapter configugration options",
    "And probably, the program output is being redirected to the REPL right now.",
    "- Consult with your debug adapter documentation",
    "https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation",
    'Usually required option is `console = "integratedterm"`',
    "- Check nvim dap issues about your debug adapter",
  }
  api.nvim_buf_set_lines(comp.buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = comp.buf })

  api.nvim_create_autocmd("User", {
    pattern = "DmSessionChanged",
    callback = vim.schedule_wrap(function()
      local session = assert(dap.session())
      local new_buf = SessionsManager.get(session).terminal or _dummy_buf
      comp.buf = new_buf
      api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
    end),
  })

  api.nvim_create_autocmd("User", {
    pattern = "DmTermAttached",
    callback = function(args)
      comp.buf = args.data.buf
      api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
    end
  })


  api.nvim_create_autocmd("User", {
    pattern = "DmTermDetached",
    callback = function()
      comp.buf = _dummy_buf
      api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
    end
  })

  return comp
end)()

UiManager.scopes = (function()
  local scopes = require("debugmaster.entities.scopes")
  local id = "debugmaster"

  local tr = tree.new {
    root = { kind = "root", children = nil },
    renderer = scopes.renderer,
    handlers = scopes.handlers,
  }

  local update_tree = function()
    local s = dap.session()
    if not s or not s.current_frame then
      return
    end
    scopes.fetch_frame(s, s.current_frame, function(to)
      if not tr.root.children then -- first init
        tr.root.children = { to }
        tr:refresh()
        return
      end
      local from = tr.root.children[1]
      scopes.sync_frame(s, from, to, function()
        tr.root.children = { to }
        tr:refresh()
      end)
    end)
  end

  after.stackTrace[id] = update_tree
  api.nvim_create_autocmd("User", {
    pattern = "DmCurrentFrameChanged",
    callback = update_tree
  })
  return {
    name = "[S]copes",
    buf = tr.buf,
  }
end)()


UiManager.sessions = (function()
  local sessions = require("debugmaster.entities.sessions")
  local tr = tree.new {
    root = sessions.build_tree(),
    renderer = sessions.renderer,
    handlers = sessions.handlers,
  }
  local refresher = function()
    tr.root = sessions.build_tree()
    tr:refresh()
  end

  dap.listeners.after.launch["random123"] = refresher
  dap.listeners.after.attach["random123"] = refresher

  return {
    name = "Sessions",
    buf = tr.buf
  }
end)()


UiManager.breakpoints = (function()
  local breakpoints = require("debugmaster.entities.breakpoints")

  local tr = tree.new {
    root = breakpoints.build_tree(SessionsManager.list_breakpoints()),
    renderer = breakpoints.renderer
  }

  api.nvim_create_autocmd("User", {
    pattern = "DmBpChanged",
    callback = function()
      print("bp changed")
      tr.root = breakpoints.build_tree(SessionsManager.list_breakpoints())
      tr:refresh()
    end
  })

  return {
    name = "[B]points",
    buf = tr.buf,
  }
end)()

UiManager.help = (function()
  local help = require("debugmaster.entities.help")
  return {
    name = "[H]elp",
    buf = help.construct(require("debugmaster.managers.DmManager").get_groups())
  }
end)()

UiManager.threads = (function()
  local threads = require("debugmaster.entities.threads")
  local tr = tree.new {
    root = { kind = "root" },
    renderer = threads.renderer,
    handlers = threads.handlers,
  }
  local update_tree = function()
    local s = dap.session()
    if not s then
      return
    end
    tr.root = { kind = "root", children = {} }
    for _, thread in pairs(s.threads --[=[@as dm.ThreadsNode[]]=]) do
      thread.kind = "thread"
      thread.children = {}
      for _, frame in ipairs(thread.frames --[=[@as dm.FrameNode[]]=]) do
        frame.kind = "frame"
        table.insert(thread.children, frame)
      end
      table.insert(tr.root.children, thread)
    end
    tr:refresh()
  end
  api.nvim_create_autocmd("User", {
    pattern = "DmCurrentFrameChanged",
    callback = update_tree,
  })
  dap.listeners.after.stackTrace["threads_widget"] = update_tree
  return {
    name = "[T]hreads",
    buf = tr.buf
  }
end)()

UiManager.sidepanel = require("debugmaster.entities.multiwin").new()
UiManager.repl = (function()
  local dap_repl = require 'dap.repl'
  local repl_buf, repl_win = dap_repl.open(nil, "vertical split")
  api.nvim_win_close(repl_win, true)
  vim.keymap.set("i", "<C-w>", "<C-S-w>", { buffer = repl_buf })
  vim.keymap.set("n", "<Tab>", "<CR>", { buffer = repl_buf, remap = true })
  vim.keymap.del("n", "o", { buffer = repl_buf })

  dap.listeners.after.initialize["repl-hl"] = function()
    pcall(vim.treesitter.stop, repl_buf)
    pcall(vim.treesitter.start, repl_buf, vim.o.filetype)
  end

  return {
    name = "[R]epl",
    buf = repl_buf,
  }
end)()

UiManager.dashboard = (function()
  return {
    -- rename to [S]tate and remove [S]copes?
    name = "[D]ashboard",
    buf = 0,
  }
end)()


UiManager.sidepanel:add_component(UiManager.dashboard)
UiManager.sidepanel:add_component(UiManager.scopes)
UiManager.sidepanel:add_component(UiManager.repl)
UiManager.sidepanel:add_component(UiManager.terminal)
UiManager.sidepanel:add_component(UiManager.help)
UiManager.sidepanel:set_active(UiManager.scopes)

return UiManager
