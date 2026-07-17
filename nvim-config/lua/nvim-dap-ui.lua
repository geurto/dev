local dap, dapui = require("dap"), require("dapui")

vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
vim.keymap.set("n", "<leader>df", function()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		local buf_name = vim.api.nvim_buf_get_name(buf)
		if buf_name:match("DAP Scopes") then
			vim.api.nvim_set_current_win(win)
			break
		end
	end
end, { desc = "Focus on Scopes" })

dapui.setup({
	layouts = {
		{
			elements = {
				{ id = "console", size = 0.5 },
				{ id = "scopes", size = 0.35 },
				{ id = "breakpoints", size = 0.15 },
			},
			size = 60,
			position = "left",
		},
	},
})

dap.listeners.after.event_initialized["dapui_config"] = function()
	local neotree_buf = vim.fn.bufnr("neo-tree")
	if neotree_buf ~= -1 and vim.api.nvim_buf_is_valid(neotree_buf) then
		vim.cmd("Neotree close")
	end
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end
