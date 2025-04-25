-- Theme configuration
local function setup_catppuccin()
	local status_ok, catppuccin = pcall(require, "catppuccin")
	if not status_ok then
		vim.notify("Failed to load catppuccin", vim.log.levels.ERROR)
		return
	end

	-- Get the mocha palette
	local colors = require("catppuccin.palettes").get_palette("mocha")

	-- Configure Catppuccin with explicit settings
	catppuccin.setup({
		flavour = "mocha",
		background = { -- :h background
			light = "latte",
			dark = "mocha",
		},
		integrations = {
			cmp = true,
			gitsigns = true,
			nvimtree = true,
			telescope = true,
			notify = true,
			mini = true,
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
