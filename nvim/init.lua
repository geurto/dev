-- plugin management with vim-plug
local data_dir = vim.fn.stdpath("data") .. "/site"
local plug_path = data_dir .. "/autoload/plug.vim"

if vim.fn.empty(vim.fn.glob(plug_path)) > 0 then
	-- Create the autoload directory if it doesn't exist
	vim.fn.system({ "mkdir", "-p", data_dir .. "/autoload" })

	-- Download vim-plug
	vim.fn.system({
		"curl",
		"-fLo",
		plug_path,
		"--create-dirs",
		"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim",
	})

	-- Auto-install plugins on first launch
	vim.cmd([[
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  ]])

	print("Installed vim-plug and plugins!")
end

local Plug = vim.fn["plug#"]
vim.call("plug#begin")

Plug("goolord/alpha-nvim")
Plug("catppuccin/nvim")
Plug("hrsh7th/cmp-buffer")
Plug("hrsh7th/cmp-cmdline")
Plug("hrsh7th/cmp-path")
Plug("hrsh7th/cmp-nvim-lsp")
Plug("saadparwaiz1/cmp_luasnip")
Plug("stevearc/conform.nvim")
Plug("lewis6991/gitsigns.nvim")
Plug("ThePrimeagen/harpoon", { ["branch"] = "harpoon2" })
Plug("maan2003/lsp_lines.nvim")
Plug("nvim-lualine/lualine.nvim")
Plug("L3MON4D3/LuaSnip")
Plug("OXY2DEV/markview.nvim")
Plug("echasnovski/mini.nvim")
Plug("nvim-neo-tree/neo-tree.nvim")
Plug("nvim-neotest/neotest")
Plug("folke/noice.nvim")
Plug("hrsh7th/nvim-cmp")
Plug("leoluz/nvim-dap-go")
Plug("rcarriga/nvim-dap-ui")
Plug("mfussenegger/nvim-dap")
Plug("theHamsta/nvim-dap-virtual-text")
Plug("neovim/nvim-lspconfig")
Plug("nvim-neotest/nvim-nio")
Plug("rcarriga/nvim-notify")
Plug("nvim-treesitter/nvim-treesitter")
Plug("nvim-tree/nvim-web-devicons")
Plug("nvim-lua/plenary.nvim")
Plug("mrcjkb/rustaceanvim")
Plug("nvim-telescope/telescope-fzf-native.nvim")
Plug("nvim-telescope/telescope.nvim")
Plug("folke/todo-comments.nvim")
Plug("folke/trouble.nvim")
Plug("folke/which-key.nvim")

vim.call("plug#end")

require("plugins.alpha")
require("plugins.catppuccin")
require("plugins.conform")
require("plugins.cpp")
require("plugins.gitsigns")
require("plugins.harpoon")
require("plugins.lualine")
require("plugins.markview")
require("plugins.mini")
require("plugins.neo-tree")
require("plugins.noice")
require("plugins.nvim-cmp")
require("plugins.nvim-dap-ui")
require("plugins.nvim-dap")
require("plugins.nvim-lspconfig")
require("plugins.nvim-notify")
require("plugins.nvim-treesitter")
require("plugins.rustaceanvim")
require("plugins.telescope")
require("plugins.todo-comments")
require("plugins.trouble")
require("plugins.which-key")

require("config.keymaps")
require("config.options")
