local dap = require("dap")

vim.keymap.set("n", "<leader>d", "<nop>", { desc = "Debug" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })
vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })

local function get_remote_host()
	local default = os.getenv("REMOTE_HOST") or "remote"
	local input = vim.fn.input("Remote host: ", default)
	return input ~= "" and input or default
end

local function remote_path_mappings(remote_root)
	remote_root = remote_root or "/root"
	return {
		{
			localRoot = vim.fn.getcwd(),
			remoteRoot = remote_root,
		},
	}
end

dap.adapters.cppdbg = {
	id = "cppdbg",
	type = "executable",
	command = vim.fn.exepath("OpenDebugAD7"),
}

dap.adapters.python = function(cb, config)
	local dap_path = vim.fn.trim(vim.fn.system("which python"))

	if config.request == "attach" then
		---@diagnostic disable-next-line: undefined-field
		local port = (config.connect or config).port
		---@diagnostic disable-next-line: undefined-field
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
			command = dap_path,
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

dap.configurations.cpp = {
	{
		name = "Local: launch",
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
		name = "Docker: Attach to gdbserver",
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
		name = "Docker: Attach to lldb-server",
		type = "lldb",
		request = "attach",
		port = 1234,
		host = "localhost",
		sourceMap = {
			["/app"] = "${workspaceFolder}",
		},
	},
}

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Local: launch",
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
		redirectOutput = true,
		justmyCode = false,
	},

	{
		name = "Docker: Remote Attach",
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
