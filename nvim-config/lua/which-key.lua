-- Properly configure which-key
local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
	vim.notify("Failed to load which-key", vim.log.levels.ERROR)
	return
end

-- Set up which-key with explicit mode configuration
which_key.setup({
	plugins = {
		marks = true,
		registers = true,
		spelling = {
			enabled = false,
		},
		presets = {
			operators = true,
			motions = true,
			text_objects = true,
			windows = true,
			nav = true,
			z = true,
			g = true,
		},
	},
	layout = {
		height = { min = 4, max = 25 },
		width = { min = 20, max = 50 },
		spacing = 3,
	},
	show_help = true,
})
