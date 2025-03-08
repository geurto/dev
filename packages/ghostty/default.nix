{
  pkgs,
  ghostty,
  neovim ? null,
}:

let
  # Wrapper script for Ghostty with proper environment variables
  ghosttyWrapper = pkgs.writeShellScriptBin "ghostty-wrapper" ''
    # Force software rendering for GTK
    export GDK_BACKEND=x11
    export LIBGL_ALWAYS_SOFTWARE=1

    # Disable problematic GTK features
    export GSK_RENDERER=cairo

    # Explicitly unset any conflicting variables
    unset GDK_DEBUG
    unset GDK_DISABLE

    # Set locale explicitly
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8

    # Run Ghostty with environment variables explicitly passed
    exec env \
      GDK_BACKEND=x11 \
      LIBGL_ALWAYS_SOFTWARE=1 \
      GSK_RENDERER=cairo \
      LANG=C.UTF-8 \
      LC_ALL=C.UTF-8 \
      ${ghostty}/bin/ghostty "$@"
  '';

  # Script to launch Ghostty with Neovim (if neovim is provided)
  ghosttyWithNeovim =
    if neovim != null then
      pkgs.writeShellScriptBin "ghostty-nvim" ''
        # Force software rendering for GTK
        export GDK_BACKEND=x11
        export LIBGL_ALWAYS_SOFTWARE=1

        # Disable problematic GTK features
        export GSK_RENDERER=cairo

        # Run Ghostty with Neovim
        exec ${ghostty}/bin/ghostty -- ${neovim}/bin/nvim "$@"
      ''
    else
      null;

  # Script to create desktop entry
  createDesktopEntry = pkgs.writeShellScriptBin "create-desktop-entry" ''
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/ghostty-nix.desktop << EOF
    [Desktop Entry]
    Name=Ghostty (Nix)
    Comment=A fast, feature-rich terminal emulator
    Exec=${ghosttyWrapper}/bin/ghostty-wrapper
    Icon=terminal
    Terminal=false
    Type=Application
    Categories=System;TerminalEmulator;
    EOF

    ${
      if neovim != null then
        ''
          cat > ~/.local/share/applications/ghostty-nvim.desktop << EOF
          [Desktop Entry]
          Name=Ghostty+Neovim
          Comment=Ghostty terminal with Neovim
          Exec=${ghosttyWithNeovim}/bin/ghostty-nvim
          Icon=nvim
          Terminal=false
          Type=Application
          Categories=Development;TextEditor;
          EOF
        ''
      else
        ""
    }

    update-desktop-database ~/.local/share/applications
    echo "Desktop entries created. You can now find Ghostty and ${
      if neovim != null then "Ghostty+Neovim " else ""
    }in your application launcher."
  '';
in
{
  wrapper = ghosttyWrapper;
  withNeovim = ghosttyWithNeovim;
  createDesktopEntry = createDesktopEntry;
}
