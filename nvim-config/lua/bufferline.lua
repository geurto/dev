-- Bufferline: browser-like tabs for open buffers
local bufferline = require("bufferline")

bufferline.setup({
	options = {
		mode = "buffers",
		-- show the position number so it matches <leader>b1..9
		numbers = "ordinal",
		diagnostics = "nvim_lsp",
		show_buffer_close_icons = false,
		show_close_icon = false,
		always_show_bufferline = true,
		separator_style = "thin",
		offsets = {
			{
				filetype = "neo-tree",
				text = "Explorer",
				highlight = "Directory",
				separator = true,
			},
		},
	},
})

-- Jump to buffer by its position in the bufferline
for i = 1, 9 do
	vim.keymap.set("n", "<leader>b" .. i, function()
		bufferline.go_to(i, true)
	end, { desc = "Go to Buffer " .. i })
end
vim.keymap.set("n", "<leader>b0", function()
	bufferline.go_to(-1, true)
end, { desc = "Go to Last Buffer" })

-- Navigation / management in bufferline order
vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bp", "<cmd>BufferLinePick<cr>", { desc = "Pick Buffer" })
vim.keymap.set("n", "<leader>bP", "<cmd>BufferLineTogglePin<cr>", { desc = "Toggle Pin" })
vim.keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close Other Buffers" })
vim.keymap.set("n", "<leader>b<", "<cmd>BufferLineMovePrev<cr>", { desc = "Move Buffer Left" })
vim.keymap.set("n", "<leader>b>", "<cmd>BufferLineMoveNext<cr>", { desc = "Move Buffer Right" })
