# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A personal Nix-based development environment providing:
- A custom Neovim configuration with multi-language LSP, debugging, and build tooling
- Terminal tools (zsh, tmux, fzf) managed via Nix flakes
- Ubuntu system dependency installation scripts
- Remote and Docker-based C++ debugging support

## Commands

### Installing / Updating

```bash
# Install packages to user profile
nix profile install .#dev .#terminal-tools

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

## Architecture

### Nix Packages

The flake defines two packages:
- **`dev`** (`.#dev`): The full neovim environment — wraps neovim with all plugins, dependencies, and the Lua config files from `nvim-config/`. Built in `nix/nvim/default.nix`.
- **`terminal-tools`** (`.#terminal-tools`): Zsh, tmux, fzf shell environment. Built in `nix/terminal-tools/`.

The neovim wrapper in `nix/nvim/default.nix` injects runtime dependencies (compilers, LSPs, debuggers, formatters) as environment variables and copies the `nvim-config/` directory into the Nix store.

### Neovim Configuration

Entry point: `nvim-config/init.lua` — loads lazy.nvim then requires each module in `nvim-config/lua/`.

Key modules:
- **`overseer-cpp.lua`**: Custom overseer.nvim task templates for CMake-based C++ projects. Handles local, Docker, and SSH remote builds and debug sessions. Most active development area.
- **`nvim-dap.lua`**: DAP adapter configurations for C++ (cppdbg/lldb), Python (debugpy), Go (delve), Rust. Includes remote/Docker attach configurations.
- **`nvim-lspconfig.lua`**: LSP server setup for clangd, rust-analyzer, gopls, lua_ls, pyright, ts_ls, svelte.

### C++ Debugging Flow

The `overseer-cpp.lua` module is the core of the remote debugging feature. It:
1. Discovers CMake-based packages in a project
2. Provides overseer task templates to build (local/remote) and launch gdbserver
3. Coordinates with `nvim-dap` to attach to the running gdbserver

The `scripts/debug_attach.sh` script handles attaching to remote processes (Python debugpy, C++ gdbserver).

### Plugin Management

Plugins are declared in `nix/nvim/plugins.nix` (Nix-managed, pinned via `flake.lock`). They are not managed by lazy.nvim at runtime — lazy.nvim is used only for loading/configuration, not installation.
