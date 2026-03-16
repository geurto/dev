-- =============================================================================
-- overseer-cpp.lua
-- Overseer tasks for building & debugging multi-package C++ CMake projects
-- Supports: local, Docker containers, SSH remote
-- =============================================================================
--
-- Directory layout assumed:
--   <repo-root>/
--     .nvim/clangd/            -- out-of-source build dir (created automatically)
--     .nvim/clangd/build_setup.sh  -- optional: extra env setup (e.g. source ROS2)
--     pkg_a/CMakeLists.txt
--     pkg_b/CMakeLists.txt
--     ...
--
-- Usage:
--   :OverseerRun cpp_build          -- pick a package, configure + build
--   :OverseerRun cpp_debug          -- build then launch nvim-dap on chosen executable
--   :OverseerRun cpp_clean          -- wipe the build directory
--   :OverseerRun cpp_configure      -- cmake configure only (no build)
--
-- Install:
--   Drop this file in  ~/.config/nvim/lua/overseer/template/  (or wherever
--   you keep custom overseer templates) and make sure overseer is set up:
--
--     require("overseer").setup()
--
-- =============================================================================

local overseer = require("overseer")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Find the repo root (first parent with .git or a top-level CMakeLists.txt).
---@return string|nil
local function find_root()
	return require("lspconfig.util").root_pattern(".git", "CMakeLists.txt")(vim.fn.expand("%:p:h"))
end

--- Discover all CMakeLists.txt files under `root` (non-recursive into build dirs).
--- Returns a list of { name = "pkg_name", path = "/abs/path/to/pkg" }.
---@param root string
---@return table[]
local function discover_packages(root)
	-- Use `find` so it works over SSH / inside containers without Lua fs deps
	local cmd = string.format(
		"find %s -name CMakeLists.txt -not -path '*/.nvim/*' -not -path '*/build/*' -not -path '*/.git/*' 2>/dev/null",
		vim.fn.shellescape(root)
	)
	local output = vim.fn.systemlist(cmd)
	local pkgs = {}
	for _, cmake_path in ipairs(output) do
		if cmake_path ~= "" then
			local pkg_dir = vim.fn.fnamemodify(cmake_path, ":h")
			local name = vim.fn.fnamemodify(pkg_dir, ":t")
			-- If the CMakeLists.txt sits at the root, call it "root"
			if pkg_dir == root then
				name = "(root)"
			end
			table.insert(pkgs, { name = name, path = pkg_dir })
		end
	end
	-- Sort alphabetically for a stable menu
	table.sort(pkgs, function(a, b)
		return a.name < b.name
	end)
	return pkgs
end

--- Prompt user to pick a package. Calls `on_choice(pkg)` with the selection.
---@param pkgs table[]
---@param on_choice fun(pkg: table)
local function pick_package(pkgs, on_choice)
	if #pkgs == 0 then
		vim.notify("No CMakeLists.txt found in project.", vim.log.levels.ERROR)
		return
	end
	if #pkgs == 1 then
		on_choice(pkgs[1])
		return
	end
	vim.ui.select(pkgs, {
		prompt = "Select C++ package to build:",
		format_item = function(pkg)
			return pkg.name .. "  (" .. pkg.path .. ")"
		end,
	}, function(choice)
		if choice then
			on_choice(choice)
		end
	end)
end

--- Detect whether we are running inside a Docker container.
---@return boolean
local function is_in_docker()
	if vim.fn.filereadable("/.dockerenv") == 1 then
		return true
	end
	local cgroup = vim.fn.system("cat /proc/1/cgroup 2>/dev/null")
	return vim.fn.match(cgroup, "docker") >= 0
end

--- Build a sanitised env table for Docker containers.
---
--- IMPORTANT: We only set PATH and "safe" variables here. Library path
--- variables (LD_LIBRARY_PATH, LIBRARY_PATH, C_INCLUDE_PATH, etc.) are
--- deliberately NOT set in the process environment. Setting them here
--- would corrupt the dynamic linker for the shell process itself, causing
--- errors like:
---   zsh: error while loading shared libraries: __vdso_time: invalid mode
---       for dlopen(): Invalid argument
---
--- Instead, library paths are exported INSIDE the build script (via
--- lib_path_exports()) so only cmake/make/gcc see them.
---
--- We also explicitly set compiler/linker path variables to empty strings
--- to prevent Nix-injected values (from the nvim process) from leaking
--- into the build. Nix-built nvim inherits vars like C_INCLUDE_PATH
--- pointing into /nix/store, which breaks GCC's #include_next chain
--- for system headers (stdlib.h, etc.).
---@return table<string,string>
local function docker_build_env()
	local env = {}
	local cur = vim.fn.environ()

	-- Start with a sane base PATH, but append any nix-related paths from
	-- the current env so mounted /nix/store binaries remain accessible.
	local base_path = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	if cur.PATH then
		local nix_paths = {}
		for segment in cur.PATH:gmatch("[^:]+") do
			if segment:match("^/nix/") or segment:match("^/home/.-/%.nix") then
				table.insert(nix_paths, segment)
			end
		end
		if #nix_paths > 0 then
			base_path = base_path .. ":" .. table.concat(nix_paths, ":")
		end
	end
	env.PATH = base_path

	local safe_vars = {
		"HOME",
		"USER",
		"TERM",
		"LANG",
		-- ROS2
		"AMENT_PREFIX_PATH",
		"COLCON_PREFIX_PATH",
		"ROS_DISTRO",
		"ROS_VERSION",
		"ROS_PACKAGE_PATH",
		"PYTHONPATH",
		-- Build
		"CMAKE_PREFIX_PATH",
		-- Nix
		"NIX_PROFILES",
		"NIX_SSL_CERT_FILE",
	}
	for _, var in ipairs(safe_vars) do
		if cur[var] ~= nil then
			env[var] = cur[var]
		end
	end

	-- Force SHELL to bash so overseer/vim.system doesn't pick up zsh or
	-- another shell from the container env that may behave differently.
	env.SHELL = "/bin/bash"

	-- Explicitly clear compiler/linker path variables that Nix may have
	-- injected into the nvim process. If left set, they pollute GCC's
	-- include search order and break #include_next for system headers.
	-- The build script will set correct values via lib_path_exports().
	env.C_INCLUDE_PATH = ""
	env.CPLUS_INCLUDE_PATH = ""
	env.LIBRARY_PATH = ""
	env.LD_LIBRARY_PATH = ""
	env.NIX_CFLAGS_COMPILE = ""
	env.NIX_LDFLAGS = ""
	env.NIX_CC_WRAPPER_TARGET_HOST = ""
	env.NIX_BINTOOLS_WRAPPER_TARGET_HOST = ""

	return env
end

--- Detect the multiarch triplet for library paths.
--- Returns e.g. "x86_64-linux-gnu" or "aarch64-linux-gnu".
---@return string
local function detect_multiarch()
	local arch = vim.fn.trim(vim.fn.system("dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null"))
	if arch == "" then
		local uname = vim.fn.trim(vim.fn.system("uname -m 2>/dev/null"))
		if uname == "aarch64" then
			arch = "aarch64-linux-gnu"
		else
			arch = "x86_64-linux-gnu"
		end
	end
	return arch
end

--- Generate shell export lines for library paths.
--- Called inside the build script so only cmake/make/gcc see these —
--- the parent shell/dynamic linker is unaffected.
---
--- These REPLACE (not append to) any existing values, because the process
--- env has been scrubbed of Nix-injected paths by docker_build_env().
---@return string
local function lib_path_exports()
	local arch = detect_multiarch()
	return string.format(
		[[# Set clean library/include paths for the system compiler.
# These replace any inherited values (Nix-injected paths are scrubbed).
export LD_LIBRARY_PATH="/usr/lib/%s"
export LIBRARY_PATH="/usr/lib/%s"
export CPLUS_INCLUDE_PATH="/usr/include/%s:/usr/include"
export C_INCLUDE_PATH="/usr/include/%s:/usr/include"
# Also unset Nix compiler wrapper variables in case they leaked through
unset NIX_CFLAGS_COMPILE NIX_LDFLAGS NIX_CC_WRAPPER_TARGET_HOST NIX_BINTOOLS_WRAPPER_TARGET_HOST 2>/dev/null || true
]],
		arch,
		arch,
		arch,
		arch
	)
end

--- Build the shell command that configures + builds a single package.
---@param root string    repo root
---@param pkg_path string absolute path to the package directory
---@param in_docker boolean whether we're in a container
---@return string
local function cmake_build_cmd(root, pkg_path, in_docker)
	local build_dir = root .. "/.nvim/clangd"
	local setup_file = "build_setup.sh"
	local source_cmd = ""
	local lib_exports = ""

	if vim.fn.filereadable(build_dir .. "/" .. setup_file) == 1 then
		source_cmd = string.format('source "%s/%s" && ', build_dir, setup_file)
	end

	if in_docker then
		lib_exports = lib_path_exports()
	end

	return string.format(
		[[set -euo pipefail
echo "=== Build started ==="
echo "Build dir: %s"
echo "Package:   %s"
%s
echo "=== Compiler env ==="
echo "  C_INCLUDE_PATH=${C_INCLUDE_PATH:-<unset>}"
echo "  CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH:-<unset>}"
echo "  LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-<unset>}"
echo "  CC=$(which cc 2>/dev/null || echo '<not found>')"
echo "  CXX=$(which c++ 2>/dev/null || echo '<not found>')"
BUILD_DIR="%s"
PKG_DIR="%s"
ROOT_DIR="%s"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Clean previous build artifacts but keep build_setup.sh
find . -maxdepth 1 -type f -not -name '%s' -delete 2>/dev/null || true
# Only remove subdirs if any exist (avoids glob failure under set -e)
if ls -d */ >/dev/null 2>&1; then
    rm -rf */
fi

echo "=== Running CMake configure ==="
%scmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug "$PKG_DIR"

echo "=== Building ==="
cmake --build . -j "$(nproc 2>/dev/null || echo 4)"

# Symlink compile_commands.json to repo root for clangd
ln -sf "$BUILD_DIR/compile_commands.json" "$ROOT_DIR/compile_commands.json"
echo "=== Build finished successfully ==="]],
		build_dir,
		pkg_path,
		lib_exports,
		build_dir,
		pkg_path,
		root,
		setup_file,
		source_cmd
	)
end

--- Find executables produced by the CMake build.
---@param root string
---@return string[]
local function find_executables(root)
	local build_dir = root .. "/.nvim/clangd"
	local cmd = string.format(
		"find %s -maxdepth 3 -type f -executable -not -name '*.so' -not -name '*.a' "
			.. "-not -name 'CMake*' -not -name '*.cmake' -not -name 'Makefile' "
			.. "-not -name '*.sh' -not -name '*.py' 2>/dev/null",
		vim.fn.shellescape(build_dir)
	)
	local output = vim.fn.systemlist(cmd)
	local exes = {}
	for _, line in ipairs(output) do
		if line ~= "" then
			table.insert(exes, line)
		end
	end
	return exes
end

--- Prompt the user to pick an executable and launch nvim-dap.
---@param root string
local function pick_and_debug(root)
	local exes = find_executables(root)
	if #exes == 0 then
		vim.notify("No executables found in .nvim/clangd/", vim.log.levels.WARN)
		return
	end

	vim.ui.select(exes, {
		prompt = "Select executable to debug:",
		format_item = function(exe)
			return vim.fn.fnamemodify(exe, ":t") .. "  (" .. exe .. ")"
		end,
	}, function(choice)
		if not choice then
			return
		end

		local dap = require("dap")

		local adapter_name = dap.adapters.codelldb and "codelldb"
			or dap.adapters.cppdbg and "cppdbg"
			or dap.adapters.gdb and "gdb"
			or nil

		if not adapter_name then
			vim.notify(
				"No C++ DAP adapter found. Configure dap.adapters.codelldb, cppdbg, or gdb.",
				vim.log.levels.ERROR
			)
			return
		end

		dap.run({
			name = "Debug: " .. vim.fn.fnamemodify(choice, ":t"),
			type = adapter_name,
			request = "launch",
			program = choice,
			cwd = root,
			stopOnEntry = false,
			args = {},
		})
	end)
end

-- ---------------------------------------------------------------------------
-- Task runner functions
-- ---------------------------------------------------------------------------

local function run_build(opts)
	opts = opts or {}
	local root = find_root()
	if not root then
		vim.notify("Cannot find project root.", vim.log.levels.ERROR)
		return
	end

	local in_docker = is_in_docker()
	local pkgs = discover_packages(root)

	pick_package(pkgs, function(pkg)
		local cmd = cmake_build_cmd(root, pkg.path, in_docker)
		local env = nil
		if in_docker then
			env = docker_build_env()
		end

		local task = overseer.new_task({
			name = "Build: " .. pkg.name,
			cmd = "/bin/bash",
			args = { "-c", cmd },
			env = env,
			cwd = root,
			components = {
				{ "on_output_quickfix", open_on_exit = "failure" },
				"on_result_diagnostics",
				"default",
			},
		})
		task:start()

		if opts.on_complete then
			task:subscribe("on_complete", function(_, status)
				if status == "SUCCESS" then
					opts.on_complete()
				else
					vim.notify("Build failed — not proceeding.", vim.log.levels.WARN)
				end
			end)
		end
	end)
end

local function run_debug()
	local root = find_root()
	if not root then
		vim.notify("Cannot find project root.", vim.log.levels.ERROR)
		return
	end

	run_build({
		on_complete = function()
			vim.schedule(function()
				pick_and_debug(root)
			end)
		end,
	})
end

local function run_clean()
	local root = find_root()
	if not root then
		vim.notify("Cannot find project root.", vim.log.levels.ERROR)
		return
	end

	local build_dir = root .. "/.nvim/clangd"
	local task = overseer.new_task({
		name = "Clean build",
		cmd = "/bin/bash",
		args = {
			"-c",
			string.format('rm -rf "%s" && echo "Build directory cleaned." || echo "Nothing to clean."', build_dir),
		},
		cwd = root,
		components = { "default" },
	})
	task:start()
end

local function run_configure()
	local root = find_root()
	if not root then
		vim.notify("Cannot find project root.", vim.log.levels.ERROR)
		return
	end

	local in_docker = is_in_docker()
	local pkgs = discover_packages(root)

	pick_package(pkgs, function(pkg)
		local build_dir = root .. "/.nvim/clangd"
		local setup_file = "build_setup.sh"
		local source_cmd = ""
		local lib_exports = ""

		if vim.fn.filereadable(build_dir .. "/" .. setup_file) == 1 then
			source_cmd = string.format('source "%s/%s" && ', build_dir, setup_file)
		end
		if in_docker then
			lib_exports = lib_path_exports()
		end

		local cmd = string.format(
			[[set -euo pipefail
%s
BUILD_DIR="%s"
PKG_DIR="%s"
ROOT_DIR="%s"

mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"
echo "=== Configuring %s ==="
%scmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug "$PKG_DIR"
ln -sf "$BUILD_DIR/compile_commands.json" "$ROOT_DIR/compile_commands.json"
echo "=== Configure done ==="]],
			lib_exports,
			build_dir,
			pkg.path,
			root,
			pkg.name,
			source_cmd
		)

		local env = nil
		if in_docker then
			env = docker_build_env()
		end

		local task = overseer.new_task({
			name = "Configure: " .. pkg.name,
			cmd = "/bin/bash",
			args = { "-c", cmd },
			env = env,
			cwd = root,
			components = {
				{ "on_output_quickfix", open_on_exit = "failure" },
				"default",
			},
		})
		task:start()
	end)
end

-- ---------------------------------------------------------------------------
-- Register as proper overseer templates (so :OverseerRun shows them)
-- ---------------------------------------------------------------------------
for _, tmpl in ipairs({
	{
		name = "cpp_build",
		desc = "CMake configure + build a C++ package",
		run = run_build,
	},
	{
		name = "cpp_debug",
		desc = "Build then debug a C++ executable with nvim-dap",
		run = run_debug,
	},
	{
		name = "cpp_clean",
		desc = "Remove the .nvim/clangd directory",
		run = run_clean,
	},
	{
		name = "cpp_configure",
		desc = "CMake configure only (no build)",
		run = run_configure,
	},
}) do
	overseer.register_template({
		name = tmpl.name,
		desc = tmpl.desc,
		builder = function()
			vim.schedule(tmpl.run)
			return nil
		end,
		condition = {
			callback = function()
				return find_root() ~= nil
			end,
		},
	})
end

-- ---------------------------------------------------------------------------
-- Keymaps
-- ---------------------------------------------------------------------------

vim.keymap.set("n", "<leader>c", "<nop>", { desc = "cpp" })
vim.keymap.set("n", "<leader>cb", run_build, { desc = "Build CMake package (overseer)" })
vim.keymap.set("n", "<leader>cd", run_debug, { desc = "Build + debug C++ (overseer + dap)" })
vim.keymap.set("n", "<leader>cc", run_configure, { desc = "CMake configure only" })
vim.keymap.set("n", "<leader>cx", run_clean, { desc = "Clean .nvim/clangd" })
