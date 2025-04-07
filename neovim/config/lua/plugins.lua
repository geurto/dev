-- plugins.lua (only used in Docker with lazy.nvim)
return {
	-- UI
	{ "catppuccin/nvim", name = "catppuccin" },
	{ "nvim-lualine/lualine.nvim" },
	{ "nvim-tree/nvim-web-devicons" },
	{ "goolord/alpha-nvim" },
	{ "folke/noice.nvim", dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	} },

	-- Navigation
	{
		"nvim-neo-tree/neo-tree.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
		},
	},
	{ "ThePrimeagen/harpoon", branch = "harpoon2" },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},

	-- Treesitter
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

	-- LSP and Completion
	{ "neovim/nvim-lspconfig" },
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
	},
	{ "mrcjkb/rustaceanvim" },
	{ "stevearc/conform.nvim" },

	-- Git
	{ "lewis6991/gitsigns.nvim" },
	{ "tpope/vim-fugitive" },

	-- Debugging
	{ "mfussenegger/nvim-dap" },
	{ "rcarriga/nvim-dap-ui" },
	{ "theHamsta/nvim-dap-virtual-text" },
	{ "leoluz/nvim-dap-go" },

	-- Testing
	{ "nvim-neotest/neotest" },

	-- Utilities
	{ "echasnovski/mini.nvim" },
	{ "folke/which-key.nvim" },
	{ "folke/todo-comments.nvim" },
	{ "folke/trouble.nvim" },
	{ "LintaoAmons/markview.nvim" },
	{ "https://gitlab.com/HiPhish/lsp_lines.nvim" },

	-- Language specific
	{ "LnL7/vim-nix" },
}
