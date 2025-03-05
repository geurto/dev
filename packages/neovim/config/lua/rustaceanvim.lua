vim.g.rustaceanvim = {
	server = {
		default_settings = {
			["rust-analyzer"] = {
				cargo = {
					-- features = {"std"},
					noDefaultFeatures = true,
				},
				checkOnSave = {
					command = "clippy",
					-- extraArgs = {"--no-default-features"},
				},
			},
		},
	},
}
