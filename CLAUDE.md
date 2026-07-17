# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A personal Nix-based development environment providing:
- A custom Neovim configuration with multi-language LSP, debugging, and build tooling
- Terminal tools (zsh, tmux, fzf) managed via Nix flakes
- Ubuntu system dependency installation scripts (i3, polybar, alacritty)
- NixOS home-manager configuration
- Remote and Docker-based C++ debugging support

## Commands

### Installing / Updating

```bash
# Install packages to user profile (Ubuntu)
nix profile install .#neovim .#terminal-tools

# Run neovim without installing (from GitHub)
nix run --extra-experimental-features "nix-command flakes" github:geurto/dev

# Build a specific package
nix build .#neovim
nix build .#terminal-tools
```

### Ubuntu System Setup

```bash
bash ubuntu/install.sh
```

Installs: build-essential, clang, gdb, cmake, Python 3, Rust (rustup), Docker, GitHub CLI, Firefox, i3lock-color (from source), alacritty (cargo), stylua (cargo), i3, polybar. Symlinks i3/polybar/alacritty configs to `~/.config/`. Creates `/opt/bin/zsh → ~/.nix-profile/bin/zsh`.

### NixOS Setup

```bash
cd nixos/
sudo nixos-rebuild switch --flake .#<hostname>
```

## Architecture

### Nix Flake Outputs

The flake (`flake.nix`) defines:
- **`default` / `neovim`** packages: The full neovim environment — wraps neovim with all plugins, runtime dependencies, and `nvim-config/` copied into the Nix store. Built in `nix/nvim/default.nix`.
- **`terminal-tools`** package: Zsh, tmux, fzf shell environment. Built in `nix/terminal-tools/`.
- **`neovim`** app: Executable app wrapper for `nix run`.
- **`lib.makeTerminalConfig`**: Exported for consumption by the NixOS flake in `nixos/`.

### Nix Neovim Build

Three files in `nix/nvim/`:
- **`default.nix`**: Builds the neovim shell wrapper. Injects runtime dependencies as environment variables (`OPENSSL_ROOT_DIR`, `spdlog_DIR`, `fmt_DIR`) and copies `nvim-config/` into the Nix store.
- **`plugins.nix`**: ~68 plugins pinned via `flake.lock`. Includes treesitter, nvim-cmp, nvim-lspconfig, nvim-dap, nvim-dap-ui, conform, telescope, harpoon (custom-built from harpoon2 branch), overseer, and more.
- **`dependencies.nix`**: 31+ runtime packages including clangd, rust-analyzer, gopls, pyright, ts_ls, svelte LSP, gdb, lldb, delve, vscode-cpptools (x86_64 only), black, isort, ruff, stylua, prettierd, nixfmt-rfc-style, podman-compose, ripgrep, openssh, sshfs, xclip, xdotool.

### Terminal Tools Configuration

`nix/terminal-tools/config.nix` is the single source of truth shared between the Ubuntu profile install and the NixOS home-manager config. It defines:
- Shell aliases (`ls`→eza, `ll`→eza, `cat`→bat, `cd`→zoxide, `lg`→lazygit)
- Starship prompt (Nerd Font icons, green/red checkmarks)
- FZF with Everforest Hard color palette and ripgrep backend
- Zsh history (10000 lines), auto-start tmux, Docker X11 passthrough helper
- Tmux: prefix=Ctrl+A, mouse enabled, vim-like pane navigation (hjkl), split with `|`/`-`

Other files in `nix/terminal-tools/`: `zsh.nix` (adds zsh-syntax-highlighting, zsh-autosuggestions, allows `~/.zshrc` overrides), `tmux.nix`, `fzf.nix`, `default.nix` (joins all into one derivation).

### NixOS Integration

`nixos/` contains:
- **`flake.nix`**: Takes this repo as an input (`inputs.dev`).
- **`home.nix`**: Home-manager config. Imports the neovim package and shared terminal config via `inputs.dev.lib.${system}.makeTerminalConfig`. Also adds Ghostty terminal (Everforest Dark Hard), gcc, cmake, ninja, python3.
- **`configuration.nix`**: System-level NixOS config.

### Neovim Configuration

Entry point: `nvim-config/init.lua` — bootstraps vim-plug on first launch, then loads lazy.nvim and requires each module in `nvim-config/lua/`.

Key modules:
- **`overseer-cpp.lua`**: Custom overseer.nvim task templates for CMake-based C++ projects. Handles local, Docker, and SSH remote builds and debug sessions. **Most active development area.** Discovers CMakeLists.txt files, builds out-of-source to `.nvim/clangd/`, generates `compile_commands.json`, handles multiarch library paths. Keymaps: `<leader>cb` (build), `<leader>cd` (debug), `<leader>cc` (configure), `<leader>cx` (clean).
- **`nvim-dap.lua`**: DAP adapter configurations for C++ (cppdbg/lldb/gdb), Python (debugpy local + remote), Go (delve), Rust (lldb). Docker attach on `localhost:1234`, SSH remote attach via `REMOTE_HOST` env var.
- **`nvim-lspconfig.lua`**: LSP setup for clangd (compilation DB at `.nvim/clangd/`, clang-tidy, background indexing), rust-analyzer, gopls, lua_ls, pyright, ts_ls, svelte.

### C++ Debugging Flow

The `overseer-cpp.lua` module:
1. Discovers CMake-based packages in the project
2. Provides overseer task templates: `cpp_build`, `cpp_debug`, `cpp_clean`, `cpp_configure`
3. Builds locally or dispatches to Docker/SSH remote
4. Coordinates with `nvim-dap` to attach to gdbserver

`scripts/debug_attach.sh` attaches to remote processes:
```bash
debug_attach.sh python <PID>           # debugpy on running process
debug_attach.sh python-launch <args>   # launch Python with debugpy
debug_attach.sh cpp <PID>              # gdbserver attach
debug_attach.sh cpp-launch <args>      # launch C++ with gdbserver
```

### Plugin Management

Plugins are declared in `nix/nvim/plugins.nix` and pinned via `flake.lock`. They are not managed by lazy.nvim at runtime — lazy.nvim is used only for loading/configuration, not installation.
