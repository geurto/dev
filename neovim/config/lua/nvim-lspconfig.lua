local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

lspconfig.clangd.setup({
	capabilities = capabilities,
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders",
		"--fallback-style=llvm",
	},
	init_options = {
		compilationDatabasePath = "build",
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
lspconfig.pyright.setup({ capabilities = capabilities })
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

local colors = require("catppuccin.palettes").get_palette()
vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = colors.red })
vim.api.nvim_set_hl(0, "DapLogPoint", { fg = colors.blue })
vim.api.nvim_set_hl(0, "DapStopped", { fg = colors.green })
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = colors.surface1 })
vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = colors.mauve })
