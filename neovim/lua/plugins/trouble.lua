vim.diagnostic.config({
	virtual_text = true, -- Show diagnostics as virtual text
	signs = true, -- Show signs in the sign column
	underline = true, -- Underline the text with an issue
	update_in_insert = false,
	severity_sort = true,
})

require("trouble").setup({
	focus = true,
})

-- keymaps
vim.keymap.set(
	"n",
	"<leader>xx",
	"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
	{ desc = "Buffer Diagnostics (Trouble)", remap = true }
)
