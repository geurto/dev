{
  config,
  pkgs,
  inputs,
  system,
  ...
}:

let
  # Neovim built by the dev flake (same config as Ubuntu)
  neovim = inputs.dev.packages.${system}.neovim;

  # Shared terminal config — ground truth lives in nix/terminal-tools/config.nix
  termConfig = inputs.dev.lib.${system}.makeTerminalConfig pkgs;
in
{
  home.username = "peter";
  home.homeDirectory = "/home/peter";
  home.stateVersion = "25.05";

  # ── Packages ──────────────────────────────────────────────────────────────
  home.packages = [
    neovim
  ]
  ++ termConfig.extraPackages
  ++ (with pkgs; [
    # Networking / infra (alongside Tailscale)
    nmap
    wireguard-tools

    # Build tools for Rust / C++ / Python work
    pkg-config
    cmake
    ninja
    python3
    python3Packages.pip
    python3Packages.virtualenv
  ]);

  # ── Ghostty terminal ──────────────────────────────────────────────────────
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      theme = "Catppuccin Mocha";
      window-decoration = "none";
      background-opacity = 0.95;
      cursor-style = "block";
      shell-integration = "zsh";
    };
  };

  # ── Zsh (config from nix/terminal-tools/config.nix) ──────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    shellAliases = termConfig.shellAliases // {
      # NixOS-specific helpers (not relevant on Ubuntu)
      rebuild = "sudo nixos-rebuild switch --flake .#nixos";
      update = "nix flake update && sudo nixos-rebuild switch --flake .#nixos";
      ros = "source /opt/ros/jazzy/setup.zsh";
    };

    initContent = termConfig.zshInitExtra;
  };

  # ── Tmux (config from nix/terminal-tools/config.nix) ─────────────────────
  programs.tmux = {
    enable = true;
    # home-manager manages the shell setting; tmuxConf covers everything else.
    extraConfig = termConfig.tmuxConf;
  };

  # ── Starship prompt (settings from nix/terminal-tools/config.nix) ─────────
  programs.starship = {
    enable = true;
    settings = termConfig.starshipSettings;
  };

  # ── Git ───────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name = "Peter";
      user.email = "your@email.com"; # fill in
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
      };
      merge.conflictstyle = "zdiff3";
      pull.rebase = true;
    };
  };

  # ── SSH agent (systemd user service) ────────────────────────────────────
  services.ssh-agent.enable = true;

  # Force SSH/git to prompt in the terminal instead of spawning a GUI dialog.
  # Without this, SSH_ASKPASS may be picked up from the system (e.g. via
  # gnome-keyring started by PAM/SDDM) and open a popup that blocks paste.
  home.sessionVariables = {
    SSH_ASKPASS = "";
    GIT_TERMINAL_PROMPT = "1";
  };

  # ── SSH ───────────────────────────────────────────────────────────────────
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
    };
  };

  # ── Cursor ────────────────────────────────────────────────────────────────
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    hyprcursor = {
      enable = true;
      size = 24;
    };
  };

  # ── XDG ───────────────────────────────────────────────────────────────────
  xdg.enable = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = { };
  };

  # ── Hyprland ────────────────────────────────────────────────────────────
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      # ── Cursor ────────────────────────────────────────────────────────────
      env = XCURSOR_THEME,Adwaita
      env = XCURSOR_SIZE,24

      # ── General ───────────────────────────────────────────────────────────
      general {
        border_size        = 1
        gaps_in            = 4
        gaps_out           = 4
        col.active_border  = rgba(657b83ff)
        col.inactive_border = rgba(272827ff)
        layout             = dwindle
      }

      decoration {
        rounding = 0
        shadow {
          enabled = false
        }
        blur {
          enabled = false
        }
      }

      animations {
        enabled = false
      }

      input {
        follow_mouse = 1
        touchpad {
          natural_scroll = true
          tap-to-click   = true
        }
      }

      dwindle {
        preserve_split = true
        force_split    = 2
      }

      misc {
        disable_hyprland_logo   = true
        disable_splash_rendering = true
      }

      # ── Startup ───────────────────────────────────────────────────────────
      exec-once = nm-applet --indicator
      exec-once = dunst
      exec-once = hypridle
      exec-once = hyprpaper
      exec-once = waybar
      # Wallpaper: configure ~/.config/hypr/hyprpaper.conf with your image path

      # ── Mouse bindings ────────────────────────────────────────────────────
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow

      # ── Core bindings ─────────────────────────────────────────────────────
      bind = SUPER,       Return,   exec,    ghostty
      bind = SUPER SHIFT, Q,        killactive
      bind = SUPER SHIFT, C,        exec,    hyprctl reload

      # App launcher (mirrors $mod+d → rofi)
      bind = SUPER, D, exec, wofi --show run

      # ── Focus (vim + arrows) ──────────────────────────────────────────────
      bind = SUPER, H,     movefocus, l
      bind = SUPER, J,     movefocus, d
      bind = SUPER, K,     movefocus, u
      bind = SUPER, L,     movefocus, r
      bind = SUPER, left,  movefocus, l
      bind = SUPER, down,  movefocus, d
      bind = SUPER, up,    movefocus, u
      bind = SUPER, right, movefocus, r

      # ── Move windows (vim + arrows) ───────────────────────────────────────
      bind = SUPER SHIFT, H,     movewindow, l
      bind = SUPER SHIFT, J,     movewindow, d
      bind = SUPER SHIFT, K,     movewindow, u
      bind = SUPER SHIFT, L,     movewindow, r
      bind = SUPER SHIFT, left,  movewindow, l
      bind = SUPER SHIFT, down,  movewindow, d
      bind = SUPER SHIFT, up,    movewindow, u
      bind = SUPER SHIFT, right, movewindow, r

      # ── Split orientation ─────────────────────────────────────────────────
      bind = SUPER, O, layoutmsg, preselect r   # horizontal (i3: split h)
      bind = SUPER, V, layoutmsg, preselect d   # vertical   (i3: split v)
      bind = SUPER, Q, layoutmsg, togglesplit   # toggle     (i3: split toggle)

      # ── Fullscreen / floating ─────────────────────────────────────────────
      bind = SUPER,       F,     fullscreen,     0
      bind = SUPER SHIFT, space, togglefloating
      bind = SUPER,       space, cyclenext,      floating

      # ── Workspace back-and-forth (i3: $mod+b) ─────────────────────────────
      bind = SUPER, B, workspace, previous

      # ── Scratchpad (i3: scratchpad) ───────────────────────────────────────
      bind = SUPER SHIFT, minus, movetoworkspace,    special
      bind = SUPER,       minus, togglespecialworkspace

      # ── Navigate workspaces ───────────────────────────────────────────────
      bind = SUPER CTRL, right, workspace, +1
      bind = SUPER CTRL, left,  workspace, -1

      # Switch to workspace
      bind = SUPER, 1, workspace, 1
      bind = SUPER, 2, workspace, 2
      bind = SUPER, 3, workspace, 3
      bind = SUPER, 4, workspace, 4
      bind = SUPER, 5, workspace, 5
      bind = SUPER, 6, workspace, 6
      bind = SUPER, 7, workspace, 7
      bind = SUPER, 8, workspace, 8

      # Move to workspace, stay on current (i3: $mod+Ctrl+N)
      bind = SUPER CTRL, 1, movetoworkspacesilent, 1
      bind = SUPER CTRL, 2, movetoworkspacesilent, 2
      bind = SUPER CTRL, 3, movetoworkspacesilent, 3
      bind = SUPER CTRL, 4, movetoworkspacesilent, 4
      bind = SUPER CTRL, 5, movetoworkspacesilent, 5
      bind = SUPER CTRL, 6, movetoworkspacesilent, 6
      bind = SUPER CTRL, 7, movetoworkspacesilent, 7
      bind = SUPER CTRL, 8, movetoworkspacesilent, 8

      # Move to workspace and follow (i3: $mod+Shift+N)
      bind = SUPER SHIFT, 1, movetoworkspace, 1
      bind = SUPER SHIFT, 2, movetoworkspace, 2
      bind = SUPER SHIFT, 3, movetoworkspace, 3
      bind = SUPER SHIFT, 4, movetoworkspace, 4
      bind = SUPER SHIFT, 5, movetoworkspace, 5
      bind = SUPER SHIFT, 6, movetoworkspace, 6
      bind = SUPER SHIFT, 7, movetoworkspace, 7
      bind = SUPER SHIFT, 8, movetoworkspace, 8

      # ── Volume ────────────────────────────────────────────────────────────
      bind = , XF86AudioMute,        exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
      bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
      bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%

      # ── Screenshots ───────────────────────────────────────────────────────
      # Full screen → file
      bind = ,           print, exec, grim ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png
      # Active window → file
      bind = SUPER,      print, exec, grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png
      # Region → file
      bind = SHIFT,      print, exec, grim -g "$(slurp)" ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png
      # Full screen → clipboard
      bind = CTRL,       print, exec, grim - | wl-copy
      # Active window → clipboard
      bind = CTRL SUPER, print, exec, grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | wl-copy
      # Region → clipboard
      bind = CTRL SHIFT, print, exec, grim -g "$(slurp)" - | wl-copy

      # ── System mode submap (i3: $mod+0) ──────────────────────────────────
      bind = SUPER, 0, submap, system
      submap = system
      bind = ,       E,       exec,   hyprctl dispatch exit
      bind = ,       E,       submap, reset
      bind = ,       L,       exec,   hyprlock
      bind = ,       L,       submap, reset
      bind = ,       S,       exec,   systemctl suspend
      bind = ,       S,       submap, reset
      bind = ,       H,       exec,   systemctl hibernate
      bind = ,       H,       submap, reset
      bind = ,       R,       exec,   systemctl reboot
      bind = ,       R,       submap, reset
      bind = SHIFT,  S,       exec,   systemctl poweroff
      bind = SHIFT,  S,       submap, reset
      bind = ,       return,  submap, reset
      bind = ,       escape,  submap, reset
      submap = reset

      # ── Resize submap (i3: $mod+r) ────────────────────────────────────────
      bind = SUPER, R, submap, resize
      submap = resize
      binde = , H,     resizeactive, -50 0
      binde = , J,     resizeactive, 0 50
      binde = , K,     resizeactive, 0 -50
      binde = , L,     resizeactive, 50 0
      binde = , left,  resizeactive, -100 0
      binde = , down,  resizeactive, 0 100
      binde = , up,    resizeactive, 0 -100
      binde = , right, resizeactive, 100 0
      bind  = , return, submap, reset
      bind  = , escape, submap, reset
      submap = reset
    '';
  };

  # ── Waybar ──────────────────────────────────────────────────────────────
  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        height = 24;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
          sort-by-number = true;
        };

        clock = {
          format = "%Y-%m-%d  %H:%M";
          tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        };

        pulseaudio = {
          format = " {volume}%";
          format-muted = " muted";
          on-click = "pavucontrol";
          scroll-step = 5;
        };

        network = {
          format-wifi = " {essid} ({signalStrength}%)";
          format-ethernet = " eth";
          format-disconnected = " disconnected";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        battery = {
          format = " {capacity}%";
          format-charging = " {capacity}%";
          states = {
            warning = 30;
            critical = 15;
          };
        };

        tray = {
          spacing = 8;
        };
      }
    ];

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background-color: #272827;
        color: #657b83;
      }

      #workspaces button {
        padding: 0 8px;
        background-color: transparent;
        color: #657b83;
        border-bottom: 2px solid transparent;
      }

      #workspaces button.active {
        color: #ffffff;
        border-bottom: 2px solid #657b83;
      }

      #workspaces button.urgent {
        color: #ffffff;
        background-color: #c0392b;
      }

      #workspaces button:hover {
        background-color: #3c3e3d;
      }

      #clock,
      #pulseaudio,
      #network,
      #battery,
      #tray {
        padding: 0 10px;
        color: #657b83;
      }

      #battery.warning {
        color: #f39c12;
      }

      #battery.critical {
        color: #e74c3c;
      }

      #battery.charging {
        color: #2ecc71;
      }
    '';
  };

  # ── Dunst (notifications) ───────────────────────────────────────────────
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 200;
        offset = "20x40";
        origin = "top-right";
        frame_width = 1;
        frame_color = "#657b83";
        font = "JetBrainsMono Nerd Font 11";
        background = "#272827";
        foreground = "#657b83";
        timeout = 5;
        corner_radius = 0;
      };
    };
  };

  # ── Hypridle (idle / lock) ───────────────────────────────────────────────
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };
      listener = [
        {
          timeout = 600; # 10 min: lock
          on-timeout = "hyprlock";
        }
        {
          timeout = 900; # 15 min: suspend
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  programs.home-manager.enable = true;
}
