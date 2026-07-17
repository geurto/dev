local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
	return
end

local dashboard = require("alpha.themes.dashboard")

-- Set header
dashboard.section.header.val = {
	[[          _____          ]],
	[[         /\    \         ]],
	[[        /::\    \        ]],
	[[       /::::\    \       ]],
	[[      /::::::\    \      ]],
	[[     /:::/\:::\    \     ]],
	[[    /:::/  \:::\    \    ]],
	[[   /:::/    \:::\    \   ]],
	[[  /:::/    / \:::\    \  ]],
	[[ /:::/    /   \:::\ ___\ ]],
	[[/:::/____/  ___\:::|    |]],
	[[\:::\    \ /\  /:::|____|]],
	[[ \:::\    /::\ \::/    / ]],
	[[  \:::\   \:::\ \/____/  ]],
	[[   \:::\   \:::\____\    ]],
	[[    \:::\  /:::/    /    ]],
	[[     \:::\/:::/    /     ]],
	[[      \::::::/    /      ]],
	[[       \::::/    /       ]],
	[[        \::/____/        ]],
	[[                         ]],
	[[                         ]],
}

-- Set menu
dashboard.section.buttons.val = {
	dashboard.button("f", "⛁  Find file", ":Telescope find_files <CR>"),
	dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
	dashboard.button("r", "★  Recently used files", ":Telescope oldfiles <CR>"),
	dashboard.button("t", "⌅  Find text", ":Telescope live_grep <CR>"),
	dashboard.button("q", "☚  Quit Neovim", ":qa<CR>"),
}

-- Set footer
local function footer()
	return "stay gold"
end

dashboard.section.footer.val = footer()

-- Highlight groups — defined explicitly so they track the colorscheme
-- rather than borrowing from syntax groups like Include/Keyword/Type.
vim.api.nvim_set_hl(0, "AlphaHeader",  { fg = "#a7c080" }) -- everforest green
vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#d4be98" }) -- everforest fg
vim.api.nvim_set_hl(0, "AlphaFooter",  { fg = "#7c8374" }) -- everforest grey

dashboard.section.header.opts.hl  = "AlphaHeader"
dashboard.section.buttons.opts.hl = "AlphaButtons"
dashboard.section.footer.opts.hl  = "AlphaFooter"

dashboard.opts.opts.noautocmd = true

-- Setup alpha
alpha.setup(dashboard.opts)
