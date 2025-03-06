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
	window = {
		border = "single",
		position = "bottom",
		margin = { 1, 0, 1, 0 },
		padding = { 1, 1, 1, 1 },
	},
	layout = {
		height = { min = 4, max = 25 },
		width = { min = 20, max = 50 },
		spacing = 3,
	},
	ignore_missing = true, -- Set to true to avoid errors on missing mappings
	hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "^:", "^ ", "^call ", "^lua " },
	show_help = true,
	triggers = "auto", -- Explicitly set triggers
	triggers_nowait = { -- Keys that should trigger immediately
		-- marks
		"`",
		"'",
		"g`",
		"g'",
		-- registers
		'"',
		"<c-r>",
		-- spelling
		"z=",
	},
	triggers_blacklist = {
		-- list of mode / prefixes that should never be hooked by WhichKey
		i = { "j", "k" },
		v = { "j", "k" },
	},
})

-- Register some basic mappings to avoid errors
which_key.register({
	["<leader>f"] = { name = "File" },
	["<leader>b"] = { name = "Buffer" },
	["<leader>g"] = { name = "Git" },
	["<leader>l"] = { name = "LSP" },
})
