-- UiController and access for each its element provider
local dap = require("dap")
local scopes = require("debugmaster.entities.scopes")
local after = dap.listeners.after
local tree = require("debugmaster.lib.tree")
local SessionsManager = require("debugmaster.managers.SessionsManager")
local api = vim.api

---@class dm.UiManagerComp
---@field name string
---@field buf number

local UiManager = {}

UiManager.terminal = (function()
  local default_buf = api.nvim_create_buf(false, true)
  local comp = {
    name = "[T]erminal",
    buf = default_buf,
  }

  local lines = {
    "Debug adapter didn't provide terminal",
    "1. Either no session is active",
    "2. Eiter you attached to the process",
    "And then you can move the neovim terminal with the program",
    "to this section using 'dm' keymap in the debug mode",
    "3. Either you need to tweak your adapter configugration options",
    "And probably, the program output is being redirected to the REPL right now.",
    "- Consult with your debug adapter documentation",
    "https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation",
    'Usually required option is `console = "integratedTerminal"`',
    "- Check nvim dap issues about your debug adapter",
  }
  api.nvim_buf_set_lines(comp.buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = comp.buf })

  api.nvim_create_autocmd("User", {
    pattern = "DmCurrentSessionChanged",
    callback = vim.schedule_wrap(function()
      local new_buf = SessionsManager.get_terminal() or default_buf
      comp.buf = new_buf
      api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
    end),
  })

  api.nvim_create_autocmd("User", {
    pattern = "DmAttachedTermChanged",
    callback = function(args)
      comp.buf = args.data.buf or default_buf
      api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
    end
  })

  return comp
end)()

UiManager.scopes = (function()
  local root = { kind = "root", children = nil, handler = scopes.root_handler }

  api.nvim_create_autocmd("User", {
    pattern = "DmCurrentFrameChanged",
    callback = function()
      local s = dap.session()
      if not s or not s.current_frame then
        return
      end
      scopes.fetch_frame(s, s.current_frame, function(to)
        if not root.children then -- first init
          root.children = { to }
          UiManager.dashboard.view:refresh(root)
          return
        end
        local from = root.children[1]
        scopes.sync_frame(s, from, to, function()
          root.children = { to }
          UiManager.dashboard.view:refresh(root)
        end)
      end)
    end
  })

  return {
    root = root,
    name = "[S]copes",
  }
end)()


UiManager.sessions = (function()
  local sessions = require("debugmaster.entities.sessions")
  local root = { children = {}, handler = sessions.root_handler }
  local view = tree.view.new { root = root, keymaps = { "<CR>" } }

  vim.api.nvim_create_autocmd("User", {
    pattern = { "DmSessionsChanged", "DmCurrentSessionChanged" },
    callback = function(args)
      root.children = {}
      for _, s in pairs(dap.sessions() --[=[@as dm.SessionNode[]]=]) do
        s.handler = sessions.session_handler
        table.insert(root.children, s)
      end
      UiManager.dashboard.view:refresh(root)
    end
  })

  return {
    root = root,
    view = view,
  }
end)()



UiManager.breakpoints = (function()
  local breakpoints = require("debugmaster.entities.breakpoints")

  local root = {
    kind = "root",
    children = breakpoints.build_bps(SessionsManager.list_breakpoints()),
    handler = breakpoints.root_handler
  }
  local view = tree.view.new { root = root, keymaps = { "<CR>", "t" } }

  api.nvim_create_autocmd("User", {
    pattern = "DmBpChanged",
    callback = function()
      root.children = breakpoints.build_bps(SessionsManager.list_breakpoints())
      UiManager.dashboard.view:refresh(root)
    end
  })

  return {
    root = root,
    view = view,
    name = "[B]points",
  }
end)()


UiManager.help = (function()
  local help = require("debugmaster.entities.help")
  ---@type dm.HelpNodeRoot
  local root = { handler = help.help_handler, groups = {} }
  local comp = { name = "[H]elp" }
  local view
  -- to fix loop require
  -- https://ericjmritz.wordpress.com/2014/02/06/lua-avoiding-stack-overflows-with-metamethods/
  return setmetatable(comp, {
    __index = function(t, k)
      print("key == ", k)
      if k == "buf" then
        if not view then
          root.groups = require("debugmaster.managers.DmManager").get_groups()
          view = tree.view.new { root = root, keymaps = {} }
        end
        return view.buf
      end
    end
  })
end)()


UiManager.threads = (function()
  local threads = require("debugmaster.entities.threads")
  ---@type dm.TreeNode
  local root = {
    children = {},
    handler = threads.root_handler,
  }

  local view = tree.view.new {
    root = root,
    keymaps = { "<CR>" }
  }

  local update_tree = function()
    local s = dap.session()
    if not s then
      return
    end
    root.children = {}
    for _, thread in pairs(s.threads --[=[@as dm.ThreadsNode[]]=]) do
      thread.handler = threads.thread_handler
      thread.children = {}
      for _, frame in ipairs(thread.frames or {} --[=[@as dm.FrameNode[]]=]) do
        frame.handler = threads.frame_handler
        table.insert(thread.children, frame)
      end
      table.insert(root.children, thread)
    end
    UiManager.dashboard.view:refresh(root)
  end

  api.nvim_create_autocmd("User", {
    pattern = "DmCurrentFrameChanged",
    callback = update_tree,
  })

  dap.listeners.after.stackTrace["threads_widget"] = update_tree
  return {
    view = view,
    name = "[T]hreads",
    root = root,
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

do
  -- local watches = require("")
  local root_handler = tree.dispatcher.new {
    render = function(node, event)
      event.out.lines = { { { "WATCHES", "WarningMsg" } } }
    end,
    keymaps = { "" }
  }
  ---@type dm.TreeNode
  local root = { handler = root_handler, children = {} }
  UiManager.watches = { root = root }
end

UiManager.dashboard = (function()
  local separator = {
    ---@type dm.TreeNodeEventHandler
    handler = function(event)
      if event.name == "render" then
        event.out.lines = {
          { { "                  " } },
          { { "------------------" } },
          { { "                  " } },
        }
      end
    end
  }

  ---@type dm.TreeNode
  local root = {
    children = {
      UiManager.scopes.root,
      separator,
      UiManager.watches.root,
      separator,
      UiManager.threads.root,
      separator,
      UiManager.breakpoints.root,
      separator,
      UiManager.sessions.root
    }
  }

  local view = tree.view.new {
    root = root,
    keymaps = { "<CR>", "t", "c", "K" },
  }

  api.nvim_create_autocmd("User", {
    pattern = "DmCurrentFrameChanged",
    callback = function()
      for _, node in ipairs(UiManager.watches.root.children) do
        scopes.eval({ expression = node.name }, function(res)
          view:refresh(node)
        end, node)
      end
    end,
  })

  api.nvim_buf_set_keymap(view.buf, "n", "a", "", {
    callback = function()
      vim.ui.input({ prompt = "Enter an expression: " }, function(res)
        scopes.eval({ expression = res }, function(res)
          if not res then
            return
          end
          table.insert(UiManager.watches.root.children, res)
          view:refresh(UiManager.watches.root)
        end)
      end)
    end
  })

  return {
    name = "[S]tate",
    buf = view.buf,
    view = view,
  }
end)()


UiManager.sidepanel:add_component(UiManager.dashboard)
UiManager.sidepanel:add_component(UiManager.repl)
UiManager.sidepanel:add_component(UiManager.terminal)
UiManager.sidepanel:add_component(UiManager.help)
UiManager.sidepanel:set_active(UiManager.dashboard)

return UiManager
