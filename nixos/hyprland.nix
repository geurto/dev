{
  pkgs,
  lib,
  isLaptop ? false,
  ...
}:

let
  cursorSize = if isLaptop then 20 else 24;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      env = [
        "XCURSOR_THEME,Adwaita"
        "XCURSOR_SIZE,${toString cursorSize}"
      ];

      general = {
        border_size = 1;
        gaps_in = 6;
        gaps_out = 6;
        "col.active_border" = "rgba(3c4841ff)";
        "col.inactive_border" = "rgba(2e383cff)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 5;
        blur.enabled = false;
        shadow.enabled = false;
      };

      animations.enabled = false;

      input = {
        follow_mouse = 1;
        kb_layout = "us";
        kb_variant = "intl";
        touchpad.natural_scroll = true;
        touchpad.tap-to-click = true;
      };

      dwindle = {
        preserve_split = true;
        force_split = 2;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      monitor = if isLaptop then [ ",preferred,auto,1" ] else [ ",preferred,auto,1" ];

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY HYPRLAND_INSTANCE_SIGNATURE"
        "nm-applet --indicator"
        "hyprpaper"
        "waybar"
        "wlsunset -l 51.9 -L 4.4 -t 2800 -T 6500"
      ]
      ++ lib.optionals isLaptop [ "blueman-applet" ];

      exec = [
        "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      bind = [
        # Core
        "SUPER, Return, exec, ghostty"
        "SUPER SHIFT, Q, killactive"
        "SUPER SHIFT, C, exec, hyprctl reload"
        "SUPER, D, exec, tofi-run | xargs hyprctl dispatch exec --"

        # Focus
        "SUPER, H, movefocus, l"
        "SUPER, J, movefocus, d"
        "SUPER, K, movefocus, u"
        "SUPER, L, movefocus, r"
        "SUPER, left, movefocus, l"
        "SUPER, down, movefocus, d"
        "SUPER, up, movefocus, u"
        "SUPER, right, movefocus, r"

        # Move windows
        "SUPER SHIFT, H, movewindow, l"
        "SUPER SHIFT, J, movewindow, d"
        "SUPER SHIFT, K, movewindow, u"
        "SUPER SHIFT, L, movewindow, r"
        "SUPER SHIFT, left, movewindow, l"
        "SUPER SHIFT, down, movewindow, d"
        "SUPER SHIFT, up, movewindow, u"
        "SUPER SHIFT, right, movewindow, r"

        # Split orientation
        "SUPER, O, layoutmsg, preselect r"
        "SUPER, V, layoutmsg, preselect d"
        "SUPER, Q, layoutmsg, togglesplit"

        # Fullscreen / floating
        "SUPER, F, fullscreen, 0"
        "SUPER SHIFT, space, togglefloating"
        "SUPER, space, cyclenext, floating"

        # Workspace navigation
        "SUPER, B, workspace, previous"
        "SUPER CTRL, right, workspace, +1"
        "SUPER CTRL, left, workspace, -1"

        # Scratchpad
        "SUPER SHIFT, minus, movetoworkspace, special"
        "SUPER, minus, togglespecialworkspace"

        # Switch to workspace
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"

        # Move to workspace, stay
        "SUPER CTRL, 1, movetoworkspacesilent, 1"
        "SUPER CTRL, 2, movetoworkspacesilent, 2"
        "SUPER CTRL, 3, movetoworkspacesilent, 3"
        "SUPER CTRL, 4, movetoworkspacesilent, 4"
        "SUPER CTRL, 5, movetoworkspacesilent, 5"
        "SUPER CTRL, 6, movetoworkspacesilent, 6"
        "SUPER CTRL, 7, movetoworkspacesilent, 7"
        "SUPER CTRL, 8, movetoworkspacesilent, 8"

        # Move to workspace and follow
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"

        # Brightness
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"

        # Volume
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"

        # System submap entry
        "SUPER, 0, submap, system"
      ];
    };

    # extraConfig only for things settings can't express:
    extraConfig = ''
      # Screenshots
      bind = , print, exec, grim ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png
      bind = SUPER, print, exec, grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png
      bind = SHIFT, print, exec, grim -g "$(slurp)" ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png
      bind = CTRL, print, exec, grim - | wl-copy
      bind = CTRL SUPER, print, exec, grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" - | wl-copy
      bind = CTRL SHIFT, print, exec, grim -g "$(slurp)" - | wl-copy

      # System submap
      submap = system
      bind = , E, exec, hyprctl dispatch exit
      bind = , E, submap, reset
      bind = , L, exec, hyprlock
      bind = , L, submap, reset
      bind = , S, exec, systemctl suspend
      bind = , S, submap, reset
      bind = , H, exec, systemctl hibernate
      bind = , H, submap, reset
      bind = , R, exec, systemctl reboot
      bind = , R, submap, reset
      bind = SHIFT, S, exec, systemctl poweroff
      bind = SHIFT, S, submap, reset
      bind = , return, submap, reset
      bind = , escape, submap, reset
      submap = reset
    '';
  };
}
