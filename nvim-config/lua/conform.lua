require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "ruff_format", "ruff_organize_imports" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		nix = { "nixfmt" },
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
		xml = { "xmlformat" },
		["xacro"] = { "xmlformat" },
		["urdf"] = { "xmlformat" },
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	formatters = {
		ruff_format = {
			command = "ruff",
			args = function()
				local config_path = vim.fs.find("pyproject.toml", {
					upward = true,
					path = vim.fn.expand("%:p:h"),
				})[1]

				local base_args = { "format", "--stdin-filename", "$FILENAME", "-" }

				if config_path then
					return { "format", "--config", config_path, "--stdin-filename", "$FILENAME", "-" }
				else
					return base_args
				end
			end,
			stdin = true,
		},
		ruff_organize_imports = {
			command = "ruff",
			args = function()
				local config_path = vim.fs.find("pyproject.toml", {
					upward = true,
					path = vim.fn.expand("%:p:h"),
				})[1]

				local base_args = { "check", "--select", "I", "--fix", "--stdin-filename", "$FILENAME", "-" }

				if config_path then
					return {
						"check",
						"--select",
						"I",
						"--fix",
						"--config",
						config_path,
						"--stdin-filename",
						"$FILENAME",
						"-",
					}
				else
					return base_args
				end
			end,
			stdin = true,
		},
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
