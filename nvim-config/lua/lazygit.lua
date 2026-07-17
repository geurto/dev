require("lazygit")
vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "LazyGit" })
vim.keymap.set("n", "<leader>gf", "<cmd>LazyGitCurrentFile<CR>", { desc = "LazyGit (current file)" })
