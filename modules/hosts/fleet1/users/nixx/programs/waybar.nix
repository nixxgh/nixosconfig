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
            height = 34;
            spacing = 4;

            modules-left = [
              "niri/workspaces"
              "niri/window"
            ];

            modules-center = [ ];

            modules-right = [
              "pulseaudio"
              "battery"
              "network"
              "bluetooth"
              "tray"
              "clock"
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
              interval = 1;
              format = "{:%H:%M:%S\n%d/%m/%y}";
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
              on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
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
              on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
            };

            bluetooth = {
              format = "󰂯";
              format-connected = "󰂱 {device_alias}";
              format-disabled = "󰂲";
              tooltip-format = "{controller_alias}\t{controller_address}";
              tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
              on-click = "${pkgs.blueman}/bin/blueman-manager";
              on-click-right = "${pkgs.bluez}/bin/bluetoothctl power toggle";
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
            background-color: rgba(26, 26, 26, 0.95);
            border-top: 1px solid rgba(60, 60, 60, 0.7);
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
            font-size: 11px;
            font-weight: 600;
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
