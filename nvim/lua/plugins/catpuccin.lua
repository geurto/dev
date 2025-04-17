-- Theme configuration
local function setup_catppuccin()
	local status_ok, catppuccin = pcall(require, "catppuccin")
	if not status_ok then
		vim.notify("Failed to load catppuccin", vim.log.levels.ERROR)
		return
	end

	-- Configure Catppuccin with explicit settings
	catppuccin.setup({
		flavour = "mocha", -- latte, frappe, macchiato, mocha
		background = { -- :h background
			light = "latte",
			dark = "mocha",
		},
		transparent_background = false,
		term_colors = true,
		dim_inactive = {
			enabled = false,
			shade = "dark",
			percentage = 0.15,
		},
		styles = {
			comments = { "italic" },
			conditionals = { "italic" },
			loops = {},
			functions = {},
			keywords = {},
			strings = {},
			variables = {},
			numbers = {},
			booleans = {},
			properties = {},
			types = {},
			operators = {},
		},
		color_overrides = {},
		custom_highlights = {
			-- Fix Neo-tree and other window separators
			VertSplit = { fg = "#6e738d" },
			NeoTreeWinSeparator = { fg = "#6e738d", bg = "#1e1e2e" },

			-- Fix floating windows
			FloatBorder = { fg = "#6e738d", bg = "#1e1e2e" },
			NormalFloat = { bg = "#1e1e2e" },

			-- Fix Trouble and other special windows
			TroubleNormal = { bg = "#1e1e2e" },
			WhichKeyFloat = { bg = "#1e1e2e" },
		},
		integrations = {
			cmp = true,
			gitsigns = true,
			nvimtree = true,
			telescope = true,
			notify = true,
			mini = true,
			-- For more plugins integrations see https://github.com/catppuccin/nvim#integrations
			neotree = true,
			which_key = true,
			indent_blankline = {
				enabled = true,
				colored_indent_levels = false,
			},
			native_lsp = {
				enabled = true,
				virtual_text = {
					errors = { "italic" },
					hints = { "italic" },
					warnings = { "italic" },
					information = { "italic" },
				},
				underlines = {
					errors = { "underline" },
					hints = { "underline" },
					warnings = { "underline" },
					information = { "underline" },
				},
			},
		},
	})

	-- Set the colorscheme
	vim.cmd.colorscheme("catppuccin")

	-- Force reload highlight groups after colorscheme is set
	vim.cmd([[
    augroup CatppuccinReload
      autocmd!
      autocmd VimEnter * lua vim.defer_fn(function() vim.cmd('doautocmd ColorScheme') end, 10)
    augroup END
  ]])
end

setup_catppuccin()
