local dap = require("dap")
local mason_path = vim.fn.stdpath("data") .. "/mason/packages"

vim.keymap.set("n", "<leader>d", "<nop>", { desc = "Debug" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })
vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })

dap.adapters.cppdbg = {
	id = "cppdbg",
	type = "executable",
	command = vim.fn.exepath("OpenDebugAD7"),
}

dap.adapters.python = {
	type = "executable",
	command = vim.fn.exepath("python3.10"), -- Use exepath to find the full path to python3
	args = { "-m", "debugpy.adapter" },
	options = {
		env = vim.empty_dict(), -- Use empty dict to not override any env vars
		inherit_env = true, -- Inherit parent process environment
	},
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
