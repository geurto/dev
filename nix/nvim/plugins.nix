{ pkgs }:
with pkgs.vimPlugins;
[
  (nvim-treesitter.withPlugins (
    plugins: with plugins; [
      c
      cpp
      go
      javascript
      python
      svelte
      typescript
      xml
    ]
  ))
  alpha-nvim
  catppuccin-nvim
  cmp-buffer
  cmp-cmdline
  cmp-nvim-lsp
  cmp-path
  cmp_luasnip
  conform-nvim
  gitsigns-nvim
  (pkgs.vimUtils.buildVimPlugin {
    pname = "harpoon";
    version = "harpoon2";
    src = pkgs.fetchFromGitHub {
      owner = "ThePrimeagen";
      repo = "harpoon";
      rev = "harpoon2";
      sha256 = "sha256-L7FvOV6KvD58BnY3no5IudiKTdgkGqhpS85RoSxtl7U=";
    };
    nvimSkipModule = [
      "harpoon.data"
      "harpoon.scratch.toggle"
      "harpoon.config"
      "harpoon"
    ];
  })
  lazygit-nvim
  lsp_lines-nvim
  lualine-nvim
  luasnip
  markview-nvim
  mini-nvim
  neo-tree-nvim
  neotest
  noice-nvim
  nvim-cmp
  nvim-dap
  nvim-dap-go
  nvim-dap-ui
  nvim-dap-virtual-text
  nvim-lspconfig
  nvim-notify
  nvim-web-devicons
  plenary-nvim
  rustaceanvim
  telescope-fzf-native-nvim
  telescope-nvim
  todo-comments-nvim
  trouble-nvim
  vim-fugitive
  vim-nix
  which-key-nvim
]
