local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

lspconfig.rust_analyzer.setup({
	capabilities = capabilities,
	cmd = { "rust-analyzer" },
	settings = {
		["rust-analyzer"] = {
			cargo = {
				noDefaultFeatures = true,
			},
			checkOnSave = {
				command = "clippy",
			},
			inlayHints = {
				parameterHints = true,
			},
		},
	},
	on_attach = function(client, bufnr) end,
})

lspconfig.clangd.setup({
	capabilities = capabilities,
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders",
	},
	init_options = {
		compilationDatabasePath = ".nvim/clangd",
	},
	on_attach = function(client, bufnr)
		client.server_capabilities.signatureHelpProvider = false
	end,
})
lspconfig.gopls.setup({
	capabilities = capabilities,
	cmd = { "gopls" },
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
				shadow = true,
			},
			staticcheck = true,
			gofumpt = true,
		},
	},
})
lspconfig.lua_ls.setup({ capabilities = capabilities })
lspconfig.pyright.setup({
	capabilities = capabilities,
	on_new_config = function(config, root_dir)
		local venv_python = root_dir .. "/.venv/bin/python"
		if vim.fn.executable(venv_python) == 1 then
			config.settings = config.settings or {}
			config.settings.python = config.settings.python or {}
			config.settings.python.pythonPath = venv_python
		end
	end,
})
lspconfig.svelte.setup({ capabilities = capabilities })
lspconfig.ts_ls.setup({ capabilities = capabilities })

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint" })
vim.fn.sign_define(
	"DapStopped",
	{ text = "", texthl = "DapStopped", numhl = "DapStopped", linehl = "DapStoppedLine" }
)
vim.fn.sign_define("DapBreakpointRejected", {
	text = "",
	texthl = "DapBreakpointRejected",
	linehl = "DapBreakpointRejected",
	numhl = "DapBreakpointRejected",
})
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint" })

vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#ea6962" })
vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#7daea3" })
vim.api.nvim_set_hl(0, "DapStopped", { fg = "#a9b665" })
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#282828" })
vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#d3869b" })
