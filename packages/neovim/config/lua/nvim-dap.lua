local dap = require("dap")
local mason_path = vim.fn.stdpath("data") .. "/mason/packages"

vim.keymap.set("n", "<leader>d", "<nop>", { desc = "Debug" })
vim.keymap.set("n", "<leader>c", "<nop>", { desc = "Code Actions" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })
vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })

-- Get it here: https://github.com/Microsoft/vscode-cpptools
dap.adapters.cppdbg = {
	id = "cppdbg",
	type = "executable",
	command = "/usr/local/bin/vscode-cpptools/extension/debugAdapters/bin/OpenDebugAD7",
	env = function()
		local variables = {}
		for k, v in pairs(vim.fn.environ()) do
			variables[string.format("%s", k)] = string.format("%s", v)
		end
		table.insert(variables, string.format("%s=%s", "TEST_VAR", "1"))
		return variables
	end,
}

dap.adapters.lldb = {
	type = "executable",
	command = vim.fn.exepath("lldb-dap"),
	name = "lldb",
}

dap.configurations.cpp = {
	{
		name = "Launch file",
		type = "cppdbg",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
}

dap.configurations.c = dap.configurations.cpp

dap.configurations.rust = {
	{
		type = "cppdbg",
		request = "launch",
		name = "Launch Rust executable",
		program = function()
			local cwd = vim.fn.getcwd()
			local cmd = "cargo build"
			local handle
			local output = ""
			handle = vim.loop.spawn(cmd, {
				args = {},
				cwd = cwd,
				stdio = { nil, nil, nil },
			}, function(code)
				handle:close()
				if code ~= 0 then
					vim.notify("Cargo build failed", vim.log.levels.ERROR)
				else
					vim.defer_fn(function()
						require("dap").continue()
					end, 100)
				end
			end)
			return vim.fn.input("Path to executable: ", cwd .. "/target/debug/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {},
		runInTerminal = false,
		setupCommands = {
			{
				text = "-enable-pretty-printing",
				description = "enable pretty printing",
				ignoreFailures = false,
			},
		},
	},
}
-- Configure debugpy for Python
dap.adapters.python = {
	type = "executable",
	command = "python",
	args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Launch file",
		program = "${file}",
		pythonPath = function()
			return "python"
		end,
	},
}
