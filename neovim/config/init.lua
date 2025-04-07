-- init.lua
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
end

-- Load Vim script configurations
local vimrc_path = vim.fn.stdpath("config") .. "/vimrc"
if vim.fn.isdirectory(vimrc_path) == 1 then
	local vimrc_files = vim.fn.glob(vimrc_path .. "/*.vim", false, true)
	for _, file in ipairs(vimrc_files) do
		vim.cmd("source " .. file)
	end
end

-- Load plugin configurations
if is_nix then
	-- In Nix, plugins are already loaded by the Nix configuration
	-- Just load your plugin configurations
	require("plugins.configs")
else
	-- In Docker, use lazy.nvim to load plugins
	require("plugins")
end

-- Load the rest of your configuration
require("settings") -- General settings
require("keymaps") -- Key mappings
require("autocmds") -- Autocommands
