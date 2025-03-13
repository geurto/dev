-- Harpoon configuration
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

-- Configure Harpoon
require("harpoon").setup({
	menu = {
		width = 60,
	},
	global_settings = {
		save_on_toggle = false,
		save_on_change = false,
		enter_on_sendcmd = false,
		tmux_autoclose_windows = false,
		excluded_filetypes = { "harpoon" },
		mark_branch = false,
	},
})

-- Basic keymaps
vim.keymap.set("n", "<leader>ha", mark.add_file, { desc = "Harpoon Add file" })

vim.keymap.set("n", "<leader>hh", ui.toggle_quick_menu, { desc = "Harpoon Menu" })

-- Navigation
vim.keymap.set("n", "<C-p>", ui.nav_prev, { desc = "Harpoon Prev buffer" })

vim.keymap.set("n", "<C-n>", ui.nav_next, { desc = "Harpoon Next buffer" })

-- Quick select
vim.keymap.set("n", "<leader>1", function()
	ui.nav_file(1)
end, { desc = "Harpoon Buffer 1" })

vim.keymap.set("n", "<leader>2", function()
	ui.nav_file(2)
end, { desc = "Harpoon Buffer 2" })

vim.keymap.set("n", "<leader>3", function()
	ui.nav_file(3)
end, { desc = "Harpoon Buffer 3" })

vim.keymap.set("n", "<leader>4", function()
	ui.nav_file(4)
end, { desc = "Harpoon Buffer 4" })

-- Delete marks
vim.keymap.set("n", "<leader>hd", mark.rm_file, { desc = "Harpoon Delete mark" })

vim.keymap.set("n", "<leader>hc", mark.clear_all, { desc = "Harpoon Clear all" })
