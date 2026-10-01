local lint = require("lint")

-- Rust is linted by rust-analyzer (clippy on save, see nvim-lspconfig.lua)
lint.linters_by_ft = {
	lua = { "luacheck" },
	python = { "ruff" },
	javascript = { "oxlint" },
	javascriptreact = { "oxlint" },
	typescript = { "oxlint" },
	typescriptreact = { "oxlint" },
	nix = { "statix", "deadnix" },
	xml = { "xmllint" },
	xacro = { "xmllint" },
	urdf = { "xmllint" },
}

-- neovim's `vim` global is expected in Lua configs
lint.linters.luacheck.args = vim.list_extend({ "--globals", "vim" }, lint.linters.luacheck.args)

local function try_lint()
	for _, name in ipairs(lint._resolve_linter_by_ft(vim.bo.filetype)) do
		local linter = lint.linters[name]
		local cmd = type(linter) == "function" and linter().cmd or linter.cmd
		if type(cmd) == "function" then
			cmd = cmd()
		end
		-- skip silently when a linter isn't installed (plain nvim without Nix)
		if cmd and vim.fn.executable(cmd) == 1 then
			lint.try_lint(name)
		end
	end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
	callback = try_lint,
})

vim.keymap.set("n", "<leader>l", try_lint, { desc = "Lint buffer" })
