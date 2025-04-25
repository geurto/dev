vim.g.rustaceanvim = {
	dap = {
		adapter = {
			type = "executable",
			command = "codelldb",
			name = "rt_lldb",
		},
		configurations = {
			{
				name = "Local: Launch",
				type = "rt_lldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
			{
				name = "Docker: Attach to lldb-server",
				type = "codelldb",
				request = "attach",
				port = 1234,
				host = "localhost",
				sourceMap = {
					["/app"] = "${workspaceFolder}",
				},
			},
		},
	},
	server = {
		default_settings = {
			["rust-analyzer"] = {
				cargo = {
					-- features = {"std"},
					noDefaultFeatures = true,
				},
				checkOnSave = {
					command = "clippy",
					-- extraArgs = {"--no-default-features"},
				},
			},
		},
	},
}

vim.keymap.set("n", "<leader>r", "<nop>", { desc = "Rustaceanvim" })
vim.keymap.set("n", "<leader>rd", "<cmd>RustLsp debuggables<cr>", { silent = true, desc = "Debug" })
vim.keymap.set("n", "<leader>rr", "<cmd>RustLsp runnables<cr>", { silent = true, desc = "Run" })
vim.keymap.set("n", "<leader>rc", "<cmd>RustLsp openCargo<cr>", { silent = true, desc = "Open Cargo.toml" })
vim.keymap.set("n", "<leader>ra", "<cmd>RustLsp codeAction<cr>", { silent = true, desc = "Code Action" })
vim.keymap.set("n", "<leader>re", "<cmd>RustLsp explainError<cr>", { silent = true, desc = "Explain Error" })
