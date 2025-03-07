-- CPP Projects Specific
vim.keymap.set("n", "<leader>c", "<nop>", { desc = "cpp" })
vim.keymap.set("n", "<leader>cb", function()
	-- Find the project root (assuming it contains a .git directory)
	local root = vim.fs.find(".git", { upward = true, type = "directory" })[1]
	if not root then
		print("Project root not found")
		return
	end
	root = vim.fs.dirname(root)

	-- Find all CMakeLists.txt files in the project
	local cmake_files = vim.fs.find("CMakeLists.txt", {
		path = root,
		type = "file",
		limit = math.huge,
	})

	if #cmake_files == 0 then
		print("No CMakeLists.txt found")
		return
	end

	-- Use the deepest CMakeLists.txt file
	local deepest_cmake = cmake_files[#cmake_files]
	local dir = vim.fs.dirname(deepest_cmake)

	-- Construct the command
	local cmd = string.format(
		"cd %s && \
    mkdir -p build && \
    cd build && \
    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_BUILD_TYPE=DEBUG .. && \
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
end, { desc = "Build CMake project" })
