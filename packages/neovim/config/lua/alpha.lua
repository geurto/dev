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
	dashboard.button("l", "♥  lazy.nvim config", ":Lazy <CR>"),
	dashboard.button("r", "★  Recently used files", ":Telescope oldfiles <CR>"),
	dashboard.button("t", "⌅  Find text", ":Telescope live_grep <CR>"),
	dashboard.button("q", "☚  Quit Neovim", ":qa<CR>"),
}

-- Set footer
local function footer()
	return "stay gold"
end

dashboard.section.footer.val = footer()

-- Set highlight
dashboard.section.footer.opts.hl = "Type"
dashboard.section.header.opts.hl = "Include"
dashboard.section.buttons.opts.hl = "Keyword"

dashboard.opts.opts.noautocmd = true

-- Setup alpha
alpha.setup(dashboard.opts)
