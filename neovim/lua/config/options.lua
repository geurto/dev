-- Set options
vim.g.mapleader = " "
vim.g.lightline = { colorscheme = "catppuccin" }
vim.g.neovide_transparency = 0.7
vim.g.neovide_cursor_animation_length = 0.015

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 2
vim.opt.showmode = false
vim.opt.hlsearch = true
vim.opt.timeoutlen = 100
vim.opt.clipboard = "unnamedplus"
vim.opt.diffopt:append("vertical")
vim.opt.shell = "zsh"

-- Set highlight groups
local highlight_groups = {
	"Normal",
	"NormalNC",
	"NvimTreeNormal",
	"NvimTreeNormalNC",
	"NeoTreeNormal",
	"NeoTreeNormalNC",
	"EndOfBuffer",
}

for _, group in ipairs(highlight_groups) do
	vim.cmd(string.format("hi %s guibg=NONE ctermbg=NONE", group))
end

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", {}),
	callback = function()
		vim.highlight.on_yank({ timeout = 350 })
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		require("alpha")
	end,
})
