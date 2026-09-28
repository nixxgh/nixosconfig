{ self, inputs, ... }: {
  flake.homeModules.waybar =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.waybar = {
        enable = true;
        systemd = {
          enable = false;
        };

        settings = {
          mainBar = {
            layer = "top";
            position = "bottom";
            height = 32;
            spacing = 4;

            modules-left = [
              "niri/workspaces"
              "niri/window"
            ];

            modules-center = [
              "clock"
            ];

            modules-right = [
              "pulseaudio"
              "battery"
              "network"
              "bluetooth"
              "tray"
            ];

            "niri/workspaces" = {
              format = "{index}";
            };

            "niri/window" = {
              format = "{}";
              max-length = 50;
              rewrite = {
                "" = "Niri";
              };
            };

            clock = {
              format = "{:%a %b %d  %H:%M}";
              tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            };

            pulseaudio = {
              format = "{icon} {volume}%";
              format-muted = "󰝟 Muted";
              format-icons = {
                default = [
                  "󰕿"
                  "󰖀"
                  "󰕾"
                ];
              };
              on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            };

            battery = {
              states = {
                warning = 30;
                critical = 15;
              };
              format = "{icon} {capacity}%";
              format-charging = "󰂄 {capacity}%";
              format-plugged = "󰚥 {capacity}%";
              format-icons = [
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
            };

            network = {
              format-wifi = "󰤨 {essid}";
              format-ethernet = "󰈀 {ipaddr}";
              format-disconnected = "󰤮 Disconnected";
              tooltip-format = "{ifname} via {gwaddr}";
            };

            bluetooth = {
              format = "󰂯";
              format-connected = "󰂱 {device_alias}";
              format-disabled = "󰂲";
              tooltip-format = "{controller_alias}\t{controller_address}";
              tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
            };

            tray = {
              icon-size = 18;
              spacing = 10;
            };
          };
        };

        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: "JetBrainsMono Nerd Font", monospace;
            font-size: 13px;
            min-height: 0;
          }

          window#waybar {
            background-color: rgba(15, 23, 42, 0.92);
            border-top: 1px solid rgba(51, 65, 85, 0.7);
            color: #f8fafc;
          }

          #workspaces button {
            padding: 0 8px;
            color: #94a3b8;
            background-color: transparent;
            border-bottom: 2px solid transparent;
          }

          #workspaces button.focused,
          #workspaces button.active {
            color: #34d399;
            border-bottom: 2px solid #10b981;
          }

          #workspaces button.urgent {
            color: #f87171;
          }

          #window {
            padding: 0 12px;
            color: #cbd5e1;
            font-weight: 500;
          }

          #clock {
            color: #ffffff;
            font-weight: bold;
            padding: 0 10px;
          }

          #pulseaudio,
          #battery,
          #network,
          #bluetooth,
          #tray {
            padding: 0 10px;
            color: #e2e8f0;
          }

          #battery.charging {
            color: #34d399;
          }

          #battery.warning:not(.charging) {
            color: #fbbf24;
          }

          #battery.critical:not(.charging) {
            color: #f87171;
          }

          #tray > .passive {
            -gtk-icon-effect: dim;
          }

          #tray > .needs-attention {
            -gtk-icon-effect: highlight;
          }
        '';
      };
    };
}
