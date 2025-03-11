local M = {}

-- https://github.com/mfussenegger/nvim-dap/issues/792
---@param dir "next"|"prev"
function M.gotoBreakpoint(dir)
	local breakpoints = require("dap.breakpoints").get()
	if #breakpoints == 0 then
		vim.notify("No breakpoints set", vim.log.levels.WARN)
		return
	end
	local points = {}
	for bufnr, buffer in pairs(breakpoints) do
		for _, point in ipairs(buffer) do
			table.insert(points, { bufnr = bufnr, line = point.line })
		end
	end

	local current = {
		bufnr = vim.api.nvim_get_current_buf(),
		line = vim.api.nvim_win_get_cursor(0)[1],
	}

	local nextPoint
	for i = 1, #points do
		local isAtBreakpointI = points[i].bufnr == current.bufnr and points[i].line == current.line
		if isAtBreakpointI then
			local nextIdx = dir == "next" and i + 1 or i - 1
			if nextIdx > #points then nextIdx = 1 end
			if nextIdx == 0 then nextIdx = #points end
			nextPoint = points[nextIdx]
			break
		end
	end
	if not nextPoint then nextPoint = points[1] end

	vim.cmd(("buffer +%s %s"):format(nextPoint.line, nextPoint.bufnr))
end

function M.make_center_float_win_cfg()
  local height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 10)))
  local width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 20)))
  ---@type vim.api.keyset.win_config
  local cfg = {
      relative = "editor",
      border = "rounded",
      width = width,
      height = height,
      row = math.ceil(vim.o.lines - height) * 0.5 - 1,
      col = math.ceil(vim.o.columns - width) * 0.5 - 1
    }
    return cfg
end

return M
