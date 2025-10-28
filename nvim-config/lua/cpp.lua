-- Function detailing how to setup debugging for your project
local function show_cpp_debug_guide()
	local debug_guide = [[
C++ Debugging Guide for Neovim
==============================

Setup Steps:
-----------
1. Create a build directory:
   $ mkdir -p .clangd 

2. Generate build files with CMake:
   $ cd .clangd && cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug ../
   
4. Link compile_commands.json to project root (for LSP):
   $ ln -s build/compile_commands.json .
]]

	-- Create a new floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(debug_guide, "\n"))

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

	-- Calculate window size and position
	local width = math.min(80, vim.o.columns - 4)
	local height = math.min(30, vim.o.lines - 4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create window options
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}

	-- Open the window
	local win = vim.api.nvim_open_win(buf, true, opts)

	-- Set mappings to close the window
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })

	-- Set window options
	vim.api.nvim_win_set_option(win, "winblend", 10)
	vim.api.nvim_win_set_option(win, "cursorline", true)
end

-- Check if we are in a Docker container to source variables
local function is_in_docker()
	local docker_env = vim.fn.filereadable("/.dockerenv") == 1

	local cgroup_content = vim.fn.system("cat /proc/1/cgroup 2>/dev/null | grep docker")
	local in_cgroup = vim.fn.match(cgroup_content, "docker") >= 0

	return docker_env or in_cgroup
end

-- When in a Docker container, we want to add system paths to build
local function get_build_env()
	local env = {}

	local function get_env_as_string(name)
		local value = vim.fn.getenv(name)
		if value == nil then
			return ""
		else
			return tostring(value)
		end
	end

	local ld_library_path = get_env_as_string("LD_LIBRARY_PATH")
	local library_path = get_env_as_string("LIBRARY_PATH")
	local cplus_include_path = get_env_as_string("CPLUS_INCLUDE_PATH")
	local c_include_path = get_env_as_string("C_INCLUDE_PATH")

	env.LD_LIBRARY_PATH = "/usr/lib/x86_64-linux-gnu:" .. ld_library_path
	env.LIBRARY_PATH = "/usr/lib/x86_64-linux-gnu:" .. library_path
	env.CPLUS_INCLUDE_PATH = "/usr/include/x86_64-linux-gnu:/usr/include:" .. cplus_include_path
	env.C_INCLUDE_PATH = "/usr/include/x86_64-linux-gnu:/usr/include:" .. c_include_path

	print("Adding system directories to build paths")

	return env
end

local function build_cmake_project()
	local root_dir = require("lspconfig.util").root_pattern(".git", "CMakeLists.txt")()

	if not root_dir then
		print("Could not find project root ('.git' or 'CMakeLists.txt').")
		return
	end

	local package_dir = vim.fs.find("CMakeLists.txt", {
		path = vim.fn.expand("%:p:h"),
		type = "file",
		upward = true,
		stop = root_dir,
	})[1]

	if not package_dir then
		print("No CMakeLists.txt found in current directory or ancestors up to project root.")
		return
	end
	package_dir = vim.fn.fnamemodify(package_dir, ":h")

	local build_dir = root_dir .. "/.clangd"

	local cmd = string.format(
		"mkdir -p %s && \
         cd %s && \
         cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug %s",
		build_dir,
		build_dir,
		package_dir
	)

	-- Create a new buffer for output
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Open a new window at the bottom with a height of 7 lines
	vim.cmd("botright 7split")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	-- Return to the previous window
	vim.cmd("wincmd p")

	-- Function to append lines to the buffer and scroll
	local function append_and_scroll(data)
		if data then
			local lines = vim.split(vim.trim(data), "\n")
			lines = vim.tbl_filter(function(line)
				return line ~= ""
			end, lines)
			if #lines > 0 then
				vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
				vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
			end
		end
	end

	local build_env = {}
	if is_in_docker() then
		build_env = vim.tbl_extend("force", vim.fn.environ(), get_build_env())
	end

	-- Run the command asynchronously
	local job = vim.system({ "/bin/bash", "-c", cmd }, {
		stdout = function(_, data)
			vim.schedule(function()
				append_and_scroll(data)
			end)
		end,
		stderr = function(_, data)
			vim.schedule(function()
				append_and_scroll(data)
			end)
		end,
		env = build_env,
	}, function(obj)
		vim.schedule(function()
			if obj.code == 0 then
				append_and_scroll("CMake build completed successfully")
				print("CMake build completed successfully")

				vim.defer_fn(function()
					vim.api.nvim_buf_delete(buf, { force = true })
				end, 1000) -- Close after 1 second
			else
				append_and_scroll("CMake build failed with exit code " .. obj.code)
				print("CMake build failed with exit code " .. obj.code)
			end
		end)
	end)

	print("CMake build started in the background...")
end

-- CPP Projects Specific
vim.keymap.set("n", "<leader>c", "<nop>", { desc = "cpp" })
vim.keymap.set("n", "<leader>cb", build_cmake_project, { desc = "Build CMake project" })
vim.keymap.set("n", "<leader>ch", show_cpp_debug_guide, { desc = "Show C++ debugging guide" })
vim.keymap.set("n", "<leader>cs", get_build_env, { desc = "Add system directories to paths" })
