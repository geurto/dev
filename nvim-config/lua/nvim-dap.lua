local dap = require("dap")

-- Keymaps
vim.keymap.set("n", "<leader>d", "<nop>", { desc = "Debug" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })
vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })

-- Helper function to get remote host
local function get_remote_host()
	local default = os.getenv("REMOTE_HOST") or "remote"
	local input = vim.fn.input("Remote host: ", default)
	return input ~= "" and input or default
end

-- ==================================================================================
-- Adapters
-- ==================================================================================
local openDebugAD7 = vim.fn.exepath("OpenDebugAD7")
if openDebugAD7 ~= "" then
	dap.adapters.cppdbg = {
		id = "cppdbg",
		type = "executable",
		command = openDebugAD7,
	}
end

dap.adapters.python = function(cb, config)
	if config.request == "attach" then
		local port = (config.connect or config).port
		local host = (config.connect or config).host or "127.0.0.1"
		cb({
			type = "server",
			port = assert(port, "`connect.port` is required for a python `attach` configuration"),
			host = host,
			options = {
				source_filetype = "python",
			},
		})
	else
		cb({
			type = "executable",
			command = vim.fn.trim(vim.fn.system("which python")),
			args = { "-m", "debugpy.adapter" },
			options = {
				source_filetype = "python",
			},
		})
	end
end

dap.adapters.lldb = {
	type = "executable",
	command = vim.fn.exepath("lldb-dap"),
	name = "lldb",
}

dap.adapters.delve = {
	type = "server",
	port = "${port}",
	executable = {
		command = "dlv",
		args = { "dap", "-l", "127.0.0.1:${port}" },
	},
}

-- ==================================================================================
-- Configurations
-- ==================================================================================
dap.configurations.cpp = {
	{
		name = "Local: launch (lldb)",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
	{
		name = "Local: launch (cppdbg)",
		type = "cppdbg",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		setupCommands = {
			{
				text = "-enable-pretty-printing",
				description = "enable pretty printing",
				ignoreFailures = false,
			},
		},
	},

	{
		name = "Docker: attach gdbserver (localhost:1234)",
		type = "cppdbg",
		request = "launch",
		MIMode = "gdb",
		miDebuggerServerAddress = "localhost:1234",
		miDebuggerPath = "/usr/bin/gdb",
		cwd = "${workspaceFolder}",
		program = "${workspaceFolder}/your_program",
		setupCommands = {
			{
				text = "-enable-pretty-printing",
				description = "enable pretty printing",
				ignoreFailures = false,
			},
		},
		sourceFileMap = {
			["/app"] = "${workspaceFolder}",
		},
	},
	{
		name = "Remote: attach gdbserver",
		type = "cppdbg",
		request = "launch",
		MIMode = "gdb",
		miDebuggerServerAddress = function()
			return get_robot_host() .. ":1234"
		end,
		miDebuggerPath = vim.fn.exepath("gdb") or "/usr/bin/gdb",
		cwd = "${workspaceFolder}",
		program = function()
			return vim.fn.input("Path to executable (for symbols): ", vim.fn.getcwd() .. "/", "file")
		end,
		setupCommands = {
			{ text = "-enable-pretty-printing", description = "enable pretty printing", ignoreFailures = false },
			{ text = "set sysroot /", description = "set sysroot for remote", ignoreFailures = true },
		},
		sourceFileMap = function()
			local remote = vim.fn.input("Remote source root: ", "/root")
			return { [remote] = vim.fn.getcwd() }
		end,
	},
}

dap.configurations.c = dap.configurations.cpp

dap.configurations.rust = {
	{
		name = "Local: Launch",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
	{
		name = "Docker: attach lldb-server (localhost:1234)",
		type = "lldb",
		request = "attach",
		port = 1234,
		host = "localhost",
		sourceMap = {
			["/app"] = "${workspaceFolder}",
		},
	},
	{
		name = "Remote: attach lldb-server",
		type = "lldb",
		request = "attach",
		port = 1234,
		host = function()
			return get_remote_host()
		end,
		sourceMap = function()
			local remote = vim.fn.input("Remote source root: ", "/root")
			return { [remote] = vim.fn.getcwd() }
		end,
	},
}

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Local: launch file",
		program = "${file}",
		pythonPath = function()
			local cwd = vim.fn.getcwd()
			if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
				return cwd .. "/venv/bin/python"
			elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
				return cwd .. "/.venv/bin/python"
			else
				return "/usr/bin/python"
			end
		end,
		console = "integratedTerminal",
		justMyCode = false,
	},

	{
		name = "Docker: attach (localhost:5678)",
		type = "python",
		request = "attach",
		connect = {
			host = "localhost",
			port = 5678,
		},
		pathMappings = {
			{
				localRoot = vim.fn.getcwd(),
				remoteRoot = "/app",
			},
		},
		justMyCode = false,
	},

	{
		type = "python",
		request = "attach",
		name = "Remote: attach (debugpy)",
		connect = function()
			return { host = get_remote_host(), port = 5678 }
		end,
		pathMappings = function()
			local remote = vim.fn.input("Remote root path: ", "/root")
			return { { localRoot = vim.fn.getcwd(), remoteRoot = remote } }
		end,
		justMyCode = false,
	},
}

dap.configurations.go = {
	{
		type = "delve",
		name = "Debug",
		request = "launch",
		program = "${file}",
	},
	{
		type = "delve",
		name = "Debug test",
		request = "launch",
		mode = "test",
		program = "${file}",
	},
	{
		type = "delve",
		name = "Debug test (go.mod)",
		request = "launch",
		mode = "test",
		program = "./${relativeFileDirname}",
	},
}
