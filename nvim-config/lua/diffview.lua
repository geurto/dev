local diffview = require("diffview")

diffview.setup({
	diff_binaries = false,
	enhanced_diff_hl = false,
	git_cmd = { "git" },
	use_icons = true,
	icons = {
		folder_closed = "",
		folder_open = "",
	},
	signs = {
		fold_closed = "",
		fold_open = "",
		done = "✓",
	},
	view = {
		default = {
			layout = "diff2_horizontal",
		},
		merge_tool = {
			layout = "diff3_horizontal",
			disable_diagnostics = true,
		},
	},
	keymaps = {
		disable_defaults = false,
	},
})

local actions = require("diffview.actions")

-- View keymaps
vim.keymap.set("n", "<tab>", actions.select_next_entry, { silent = true })
vim.keymap.set("n", "<s-tab>", actions.select_prev_entry, { silent = true })
vim.keymap.set("n", "gf", actions.goto_file_edit, { silent = true })
vim.keymap.set("n", "<C-w><C-f>", actions.goto_file_split, { silent = true })
vim.keymap.set("n", "<C-w>gf", actions.goto_file_tab, { silent = true })
vim.keymap.set("n", "<leader>e", actions.focus_files, { silent = true })
vim.keymap.set("n", "<leader>b", actions.toggle_files, { silent = true })

-- File panel keymaps
vim.keymap.set("n", "j", actions.next_entry, { silent = true })
vim.keymap.set("n", "k", actions.prev_entry, { silent = true })
vim.keymap.set("n", "<cr>", actions.select_entry, { silent = true })
vim.keymap.set("n", "R", actions.refresh_files, { silent = true })
vim.keymap.set("n", "t", actions.toggle_stage_entry, { silent = true })
vim.keymap.set("n", "S", actions.stage_all, { silent = true })
vim.keymap.set("n", "U", actions.unstage_all, { silent = true })
vim.keymap.set("n", "X", actions.restore_entry, { silent = true })
vim.keymap.set("n", "i", actions.listing_style, { silent = true })
vim.keymap.set("n", "f", actions.toggle_flatten_dirs, { silent = true })

-- Convenience mappings for merge conflict handling
vim.keymap.set("n", "<leader>gdo", ":DiffviewOpen<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gdc", ":DiffviewClose<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gdh", ":DiffviewFileHistory %<CR>", { noremap = true, silent = true })
