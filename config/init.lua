require("settings")

-- Detect environment
local is_nix = vim.fn.executable("/nix/store") == 1

-- Bootstrap plugin manager (only needed in Docker)
if not is_nix then
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not vim.loop.fs_stat(lazypath) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable", -- latest stable release
			lazypath,
		})
	end
	vim.opt.rtp:prepend(lazypath)

	require("lazy").setup("plugins")
end

-- Load plugin configurations
if is_nix then
	require("plugins.config")
end
