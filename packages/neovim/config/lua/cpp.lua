-- Function detailing how to setup debugging for your project
local function show_cpp_debug_guide()
	local debug_guide = [[
C++ Debugging Guide for Neovim
==============================

Setup Steps:
-----------
1. Create a build directory:
   $ mkdir -p build

2. Generate build files with CMake:
   $ cd build && cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug ../
   
3. Build your project:
   $ make

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

-- function to build the local CMake project
local function build_cmake_project()
	local dir = vim.fn.expand("%:p:h")

	-- Find all CMakeLists.txt files in the project
	local cmake_files = vim.fs.find("CMakeLists.txt", {
		path = dir,
		type = "file",
		limit = math.huge,
	})

	if #cmake_files == 0 then
		print(
			"No CMakeLists.txt found in "
				.. dir
				.. " -- please run this command in a directory containing a CMakeLists.txt file."
		)
		return
	end

	-- Construct the command
	local cmd = string.format(
		"cd %s && \
    mkdir -p build && \
    cd build && \
    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug ../ && \
    make && \
    cd .. && \
    if [ ! -L compile_commands.json ] && [ -f build/compile_commands.json ]; then \
        ln -sf build/compile_commands.json compile_commands.json; \
    fi",
		dir
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

	local build_env = get_build_env()

	-- Run the command asynchronously
	local job = vim.system({ "sh", "-c", cmd }, {
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

-- Check if we are in a Docker container to source variables
local function is_in_docker()
	local docker_env = vim.fn.filereadable("/.dockerenv") == 1

	local cgroup_content = vim.fn.systme("cat /proc/1/cgroup 2>/dev/null | grep docker")
	local in_cgroup = vim.fn.match(cgroup_content, "docker") >= 0

	return docker_env or in_cgroup
end

-- When in a Docker container, we want to add system paths to build
local function get_build_env()
	local env = {}

	if is_in_docker() then
		local ld_library_path = vim.fn.getenv("LD_LIBRARY_PATH") or ""
		local library_path = vim.fn.getenv("LIBRARY_PATH") or ""
		local cplus_include_path = vim.fn.getenv("CPLUS_INCLUDE_PATH") or ""
		local c_include_path = vim.fn.getenv("C_INCLUDE_PATH") or ""

		env.LD_LIBRARY_PATH = "/usr/lib/x86_64-linux-gnu:" .. ld_library_path
		env.LIBRARY_PATH = "/usr/lib/x86_64-linux-gnu:" .. library_path
		env.CPLUS_INCLUDE_PATH = "/usr/include/x86_64-linux-gnu:/usr/include:" .. cplus_include_path
		env.C_INCLUDE_PATH = "/usr/include/x86_64-linux-gnu:/usr/include:" .. c_include_path

		print("Docker environment detected: Adding system directories to build paths")
	end
end

-- CPP Projects Specific
vim.keymap.set("n", "<leader>c", "<nop>", { desc = "cpp" })
vim.keymap.set("n", "<leader>cb", build_cmake_project, { desc = "Build CMake project" })
vim.keymap.set("n", "<leader>ch", show_cpp_debug_guide, { desc = "Show C++ debugging guide" })
vim.keymap.set("n", "<leader>cs", get_build_env, { desc = "Add system directories to paths" })
