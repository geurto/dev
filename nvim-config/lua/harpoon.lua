-- Harpoon configuration
local harpoon = require("harpoon")

harpoon:setup()

-- Basic keymaps
vim.keymap.set("n", "<leader>ha", function()
	harpoon:list():add()
end, { desc = "Harpoon Add file" })
vim.keymap.set("n", "<leader>hh", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon Menu" })

-- Navigation
vim.keymap.set("n", "<C-p>", function()
	harpoon:list():prev()
end, { desc = "Harpoon Prev buffer" })
vim.keymap.set("n", "<C-n>", function()
	harpoon:list():next()
end, { desc = "Harpoon Next buffer" })

-- Quick select
vim.keymap.set("n", "<leader>1", function()
	harpoon:list():select(1)
end, { desc = "Harpoon Buffer 1" })
vim.keymap.set("n", "<leader>2", function()
	harpoon:list():select(2)
end, { desc = "Harpoon Buffer 2" })
vim.keymap.set("n", "<leader>3", function()
	harpoon:list():select(3)
end, { desc = "Harpoon Buffer 3" })
vim.keymap.set("n", "<leader>4", function()
	harpoon:list():select(4)
end, { desc = "Harpoon Buffer 4" })

-- Delete marks
vim.keymap.set("n", "<leader>hd", function()
	harpoon:list():remove()
end, { desc = "Harpoon Delete mark" })
vim.keymap.set("n", "<leader>hc", function()
	harpoon:list():clear()
end, { desc = "Harpoon Clear all" })
