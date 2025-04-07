require("nvim-treesitter.configs").setup({
	ensure_installed = {}, -- Parsers are installed in the nix config
	highlight = { enable = true },
	indent = { enable = true },
})
