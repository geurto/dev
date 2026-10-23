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
	yaml = { "yamllint" },
	sh = { "shellcheck" },
	bash = { "shellcheck" },
	cmake = { "cmakelint" },
	cpp = { "cppcheck" },
	c = { "cppcheck" },
	dockerfile = { "hadolint" },
	markdown = { "markdownlint-cli2" },
	["*"] = { "typos" },
}

-- ROS description files are plain XML
vim.filetype.add({ extension = { urdf = "urdf", xacro = "xacro" } })

-- neovim's `vim` global is expected in Lua configs
lint.linters.luacheck.args = vim.list_extend({ "--globals", "vim" }, lint.linters.luacheck.args)

-- nvim-lint has no built-in xmllint linter; messages look like `-:3: parser error : msg`
lint.linters.xmllint = {
	cmd = "xmllint",
	stdin = true,
	stream = "stderr",
	ignore_exitcode = true,
	args = { "--noout", "-" },
	parser = require("lint.parser").from_pattern("^%-:(%d+): (%w+) ?%w* : (.+)$", { "lnum", "severity", "message" }, {
		error = vim.diagnostic.severity.ERROR,
		warning = vim.diagnostic.severity.WARN,
	}, { source = "xmllint" }),
}

local function try_lint()
	local names = vim.deepcopy(lint._resolve_linter_by_ft(vim.bo.filetype))
	if vim.bo.filetype == "yaml" and vim.api.nvim_buf_get_name(0):find("/%.github/workflows/") then
		table.insert(names, "actionlint")
	end
	for _, name in ipairs(names) do
		local linter = lint.linters[name]
		local cmd = linter and (type(linter) == "function" and linter().cmd or linter.cmd)
		if type(cmd) == "function" then
			cmd = cmd()
		end
		-- skip silently when a linter is unknown or isn't installed (plain nvim without Nix)
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
