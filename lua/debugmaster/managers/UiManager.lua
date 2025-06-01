-- UiController and access for each its element provider
local dap = require("dap")
local scopes = require("debugmaster.entities.scopes")
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
    pattern = "DmCurTermChanged",
    callback = function()
      comp.buf = SessionsManager.get_terminal() or default_buf
      api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
    end
  })

  return comp
end)()

UiManager.scopes = (function()
  local root = {
    render = function(_, out)
      out.lines = {
        { { "SCOPES:", "WarningMsg" }, },
        {
          { "1. Expand node - <CR> ", "Comment" },
          { "2. Expand recursively - r ", "Comment" },
          { "3. Send to watches - a", "Comment" },
        }
      }
    end
  }

  api.nvim_create_autocmd("User", {
    pattern = "DmCurFrameChanged",
    callback = function()
      local s = dap.session()
      if not s or not s.current_frame then
        return
      end
      scopes.fetch_frame(s, s.current_frame, function(scopes_list)
        if not root.children then
          root.children = scopes_list
          UiManager.dashboard.view:refresh(root)
          return
        end
        scopes.sync_scopes(s, root.children, scopes_list, function()
          root.children = scopes_list
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
  local root = {
    render = function(_, out)
      out.lines = {
        { { "SESSIONS:", "WarningMsg" } },
      }
    end
  }
  local view = tree.view.new { root = root, keymaps = { "<CR>" } }

  vim.api.nvim_create_autocmd("User", {
    pattern = { "DmSessionsChanged", "DmCurrentSessionChanged" },
    callback = function()
      root.children = SessionsManager.list_sessions()
      UiManager.dashboard.view:refresh(root)
    end
  })

  return {
    root = root,
    view = view,
  }
end)()



UiManager.breakpoints = (function()
  local root = {
    kind = "root",
    children = SessionsManager.list_breakpoints(),
    render = function(_, out)
      out.lines = {
        { { "BREAKPOINTS:", "WarningMsg" } },
        { { "1. t - remove breakpoint ", "Comment" }, { "2. c - change breakpoint condition", "Comment" } },
      }
    end
  }

  local view = tree.view.new { root = root, keymaps = { "<CR>", "t" } }

  api.nvim_create_autocmd("User", {
    pattern = "DmBpChanged",
    callback = function()
      root.children = SessionsManager.list_breakpoints()
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
  ---@type dm.Help
  local root = setmetatable({ groups = {} }, help.Help)
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
  local root = {
    children = {},
    render = function(_, out)
      out.lines = {
        { { "THREADS", "WarningMsg" } },
        { { "Hint: navigate frames using [s and ]s", "Comment" } }
      }
    end
  }

  local view = tree.view.new { root = root, keymaps = { "<CR>" } }

  api.nvim_create_autocmd("User", {
    pattern = "DmCurFrameChanged",
    callback = function()
      root.children = SessionsManager.list_threads()
      UiManager.dashboard.view:refresh(root)
    end
  })

  return {
    view = view,
    name = "[T]hreads",
    root = root,
  }
end)()

UiManager.sidepanel = require("debugmaster.entities.multiwin").new()

UiManager.repl = (function()
  local dap_repl = require("dap.repl")
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
  local root = {
    render = function(_, out)
      out.lines = {
        { { "WATCHES", "WarningMsg" } },
        { { "1. Remove an entry - d ", "Comment" }, { "2. X -  in debug mode to add last deleted text here", "Comment" } },
      }
    end,
    children = {},
  }

  UiManager.watches = {
    root = root,
    remove = function(target)
      for i, node in ipairs(root.children) do
        if node == target then
          table.remove(root.children, i)
        end
      end
    end,
    add = function(expr, cb)
      for i, node in ipairs(root.children) do
        if node.evaluateName == expr then
          table.remove(root.children, i)
          cb()
          return
        end
      end
      scopes.eval({ expression = expr }, function(res)
        if not res then
          return
        end
        table.insert(root.children, res)
        cb()
      end)
    end
  }
end

UiManager.dashboard = (function()
  local separator = {
    render = function(_, out)
      out.lines = {
        { { "                  " } },
        { { "------------------" } },
        { { "                  " } },
      }
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
    keymaps = { "<CR>", "t", "c", "K", "r", "d", "a" },
  }

  api.nvim_create_autocmd("User", {
    pattern = "DmCurFrameChanged",
    callback = function()
      for _, node in ipairs(UiManager.watches.root.children) do
        scopes.eval({ expression = node.name }, function(res)
          view:refresh(node)
        end, node)
      end
    end,
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
