-- Set options
vim.g.mapleader = " "
vim.g.lightline = { colorscheme = "everforest" }
vim.g.neovide_transparency = 0.7
vim.g.neovide_cursor_animation_length = 0.015

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 2
vim.opt.showmode = false
vim.opt.hlsearch = true
vim.opt.timeoutlen = 100
vim.opt.clipboard = "unnamedplus"

-- Inside a container there's no usable X/Wayland clipboard, so copy via
-- OSC 52 escape sequences, which the host terminal turns into a clipboard
-- write. Paste reads the local register instead of an OSC 52 query, since
-- alacritty doesn't answer those (paste from the host with Ctrl+Shift+V).
local in_container = vim.uv.fs_stat("/.dockerenv") or vim.uv.fs_stat("/run/.containerenv")
if in_container then
	local osc52 = require("vim.ui.clipboard.osc52")
	local function paste()
		return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
	end
	vim.g.clipboard = {
		name = "OSC 52",
		copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
		paste = { ["+"] = paste, ["*"] = paste },
	}
end
vim.opt.diffopt:append("vertical")
vim.opt.shell = "zsh"

-- Clear backgrounds so Neovim uses the terminal's background colour.
-- Registered as a ColorScheme autocmd so it re-applies after every
-- colorscheme change, including the deferred `doautocmd ColorScheme`
-- fired by everforest.lua on VimEnter (which would otherwise reset
-- these groups back to the theme's hard background).
local transparent_groups = {
	"Normal",
	"NormalNC",
	"NeoTreeNormal",
	"NeoTreeNormalNC",
	"EndOfBuffer",
}

local function clear_backgrounds()
	for _, group in ipairs(transparent_groups) do
		vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
	end
end

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = clear_backgrounds,
})
clear_backgrounds()

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
