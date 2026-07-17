{
  pkgs,
  isLaptop ? false,
  ...
}:

let
  fontSize = if isLaptop then 11 else 13;
  barHeight = if isLaptop then 20 else 24;
in
{
  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        height = barHeight;

        modules-left = [
          "clock"
          "network"
          "bluetooth"
          "hyprland/window"
        ];

        modules-center = [
          "hyprland/workspaces"
          "pulseaudio"
        ]
        ++ (if isLaptop then [ "backlight" ] else [ ]);

        modules-right = [
          "cpu"
          "memory"
          "network#traffic"
          "battery"
        ];

        "hyprland/window" = {
          format = "{initialTitle}";
          separate-outputs = true;
        };

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
          sort-by-number = true;
          format-icons = {
            active = "{id}";
            default = "";
            urgent = "";
          };
          persistent-workspaces = {
            "*" = 6;
          };
        };

        clock = {
          format = "󰥔 {:%Y-%m-%d  %H:%M}";
          tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        };

        network = {
          format-wifi = " {essid} ({signalStrength}%)";
          format-ethernet = " 󰈀 {ipaddr}";
          format-disconnected = "󰖪 off";
          tooltip-format = "{ifname}: {ipaddr}\n↑ {bandwidthUpBits}  ↓ {bandwidthDownBits}";
          on-click = "nm-connection-editor";
        };

        bluetooth = {
          format = "{icon} {status}";
          format-icons = {
            enabled = "";
            disabled = "";
          };
          tooltip-format = "{device_alias}";
          on-click = "blueman-manager";
        };

        cpu = {
          interval = 5;
          format = " 󰍛 {usage}%";
          tooltip = true;
        };

        memory = {
          interval = 5;
          format = " 󰘚 {used:0.1f}G / {total:0.1f}G";
          tooltip-format = "RAM: {used:0.1f}G used\nSwap: {swapUsed:0.1f}G used";
        };

        disk = {
          interval = 30;
          format = " 󰋊 {usage}%";
        };

        "network#traffic" = {
          interval = 2;
          format = "↑ {bandwidthUpBits} ↓ {bandwidthDownBits}";
          format-disconnected = "";
          tooltip = false;
        };

        pulseaudio = {
          format = " {icon} {volume}%";
          format-muted = "󰖁 muted";
          format-icons = {
            default = [
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pavucontrol";
          scroll-step = 1;
        };

        battery = {
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          states = {
            warning = 30;
            critical = 15;
          };
        };
      }
    ];

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: ${toString fontSize}px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }
    ''
    + builtins.readFile ./waybar/style.css;
  };
}
