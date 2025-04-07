-- Basic options
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 2
vim.opt.showmode = false
vim.opt.hlsearch = true
vim.opt.timeoutlen = 100
vim.opt.clipboard:append("unnamedplus")
vim.opt.diffopt:append("vertical")

-- Transparent background
local function set_transparent_bg()
	local groups = {
		"Normal",
		"NormalNC",
		"NvimTreeNormal",
		"NvimTreeNormalNC",
		"NeoTreeNormal",
		"NeoTreeNormalNC",
		"EndOfBuffer",
	}
	for _, group in ipairs(groups) do
		vim.cmd("hi " .. group .. " guibg=NONE ctermbg=NONE")
	end
end

-- Apply transparent background
set_transparent_bg()

-- Load alpha on startup
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		require("alpha")
	end,
})

-- Return the module
return {}
