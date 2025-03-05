require("gitsigns").setup()

vim.keymap.set(
	"n",
	"<leader>ghh",
	":Gitsigns preview_hunk_inline<CR>",
	{ desc = "Hunk Change Preview" },
	{ noremap = true, silent = true }
)
vim.keymap.set("n", "<leader>ghn", ":Gitsigns next_hunk<CR>", { desc = "Next Hunk" }, { noremap = true, silent = true })
vim.keymap.set(
	"n",
	"<leader>ghp",
	":Gitsigns prev_hunk<CR>",
	{ desc = "Previous Hunk" },
	{ noremap = true, silent = true }
)
vim.keymap.set(
	"n",
	"ghh",
	":Gitsigns preview_hunk_inline<CR>",
	{ desc = "Hunk Change Preview" },
	{ noremap = true, silent = true }
)
vim.keymap.set(
	"n",
	"ghn",
	":Gitsigns next_hunk<CR>:Gitsigns preview_hunk_inline<CR>",
	{ desc = "Next Hunk" },
	{ noremap = true, silent = true }
)
vim.keymap.set(
	"n",
	"ghp",
	":Gitsigns prev_hunk<CR>:Gitsigns preview_hunk_inline<CR>",
	{ desc = "Previous Hunk" },
	{ noremap = true, silent = true }
)
