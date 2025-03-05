require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		rust = {
			"rustfmt",
			extra_args = function()
				local config_path = vim.fn.getcwd() .. "/rustfmt.toml"
				if vim.fn.filereadable(config_path) == 1 then
					return { "--config-path", vim.fn.getcwd(), "--unstable-features" }
				else
					return { "--unstable-features" }
				end
			end,
		},
		nix = { "nixfmt" },
		xml = { "xmlformat" },
		["xacro"] = { "xmlformat" },
		["urdf"] = { "xmlformat" },
	},
	-- Set default options
	default_format_opts = {
		lsp_format = "fallback",
	},
	-- Set up format-on-save
	format_on_save = { timeout_ms = 500 },
	-- Customize formatters
	formatters = {
		shfmt = {
			prepend_args = { "-i", "2" },
		},
	},
})
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function()
		require("conform").format()
	end,
})
