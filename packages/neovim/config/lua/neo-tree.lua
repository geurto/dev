-- Neo-tree core configuration
local status_ok, neotree = pcall(require, "neo-tree")
if not status_ok then
	vim.notify("Failed to load neo-tree", vim.log.levels.ERROR)
	return
end

-- Setup Neo-tree
neotree.setup({
	sources = { "filesystem", "buffers", "git_status" },
	open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
	filesystem = {
		bind_to_cwd = false,
		follow_current_file = { enabled = true },
		use_libuv_file_watcher = true,
	},
	window = {
		mappings = {
			["l"] = "open",
			["h"] = "close_node",
			["<space>"] = "none",
			["Y"] = {
				function(state)
					local node = state.tree:get_node()
					local path = node:get_id()
					vim.fn.setreg("+", path, "c")
				end,
				desc = "Copy Path to Clipboard",
			},
			["O"] = {
				function(state)
					-- Use vim.fn.system instead of lazy.util.open
					local path = state.tree:get_node().path
					if vim.fn.has("mac") == 1 then
						vim.fn.system({ "open", path })
					elseif vim.fn.has("unix") == 1 then
						vim.fn.system({ "xdg-open", path })
					elseif vim.fn.has("win32") == 1 then
						vim.fn.system({ "cmd.exe", "/c", "start", "", path })
					end
				end,
				desc = "Open with System Application",
			},
			["P"] = { "toggle_preview", config = { use_float = false } },
		},
	},
	default_component_configs = {
		indent = {
			with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
			expander_collapsed = "",
			expander_expanded = "",
			expander_highlight = "NeoTreeExpander",
		},
		git_status = {
			symbols = {
				unstaged = "󰄱",
				staged = "󰱒",
			},
		},
	},
})

-- Set up event handlers
local events = require("neo-tree.events")
local function on_move(data)
	-- Check if Snacks module exists before using it
	if package.loaded["Snacks"] and package.loaded["Snacks"].rename then
		package.loaded["Snacks"].rename.on_rename_file(data.source, data.destination)
	end
end

-- Register event handlers
events.subscribe({
	event = events.FILE_MOVED,
	handler = on_move,
})
events.subscribe({
	event = events.FILE_RENAMED,
	handler = on_move,
})

-- Set up TermClose autocmd for lazygit
vim.api.nvim_create_autocmd("TermClose", {
	pattern = "*lazygit",
	callback = function()
		if package.loaded["neo-tree.sources.git_status"] then
			require("neo-tree.sources.git_status").refresh()
		end
	end,
})
