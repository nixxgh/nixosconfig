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
              "custom/launcher"
              "niri/workspaces"
              "niri/window"
            ];

            modules-center = [ ];

            modules-right = [
              "pulseaudio"
              "battery"
              "network"
              "bluetooth"
              "custom/nightlight"
              "custom/caffeine"
              "custom/notification"
              "tray"
              "clock"
            ];

            "custom/launcher" = {
              format = "󰍉 Search...";
              tooltip = true;
              tooltip-format = "Search Applications (Mod+S)";
              on-click = "${pkgs.fuzzel}/bin/fuzzel";
            };

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
            };

            "custom/nightlight" = {
              format = "{}";
              return-type = "json";
              interval = 2;
              exec = "${pkgs.writeShellScript "waybar-nightlight-status" ''
                if ${pkgs.systemd}/bin/systemctl --user is-active --quiet wlsunset-forced; then
                  echo '{"text":"󰌵 On","class":"on","tooltip":"Night Light: Forced ON (Locked 4000K)\nClick for OFF | Right-click for Auto"}'
                elif ${pkgs.systemd}/bin/systemctl --user is-active --quiet wlsunset; then
                  echo '{"text":"󰌵 Auto","class":"auto","tooltip":"Night Light: Auto (Solar Cycle: 6500K ↔ 4000K)\nClick for Forced ON | Right-click for Auto"}'
                else
                  echo '{"text":"󰌶 Off","class":"off","tooltip":"Night Light: Forced OFF (Standard 6500K)\nClick for Auto | Right-click for Auto"}'
                fi
              ''}";
              on-click = "${pkgs.writeShellScript "waybar-nightlight-toggle" ''
                if ${pkgs.systemd}/bin/systemctl --user is-active --quiet wlsunset-forced; then
                  ${pkgs.systemd}/bin/systemctl --user stop wlsunset-forced
                  ${pkgs.systemd}/bin/systemctl --user stop wlsunset
                elif ${pkgs.systemd}/bin/systemctl --user is-active --quiet wlsunset; then
                  ${pkgs.systemd}/bin/systemctl --user stop wlsunset
                  ${pkgs.systemd}/bin/systemctl --user start wlsunset-forced
                else
                  ${pkgs.systemd}/bin/systemctl --user stop wlsunset-forced
                  ${pkgs.systemd}/bin/systemctl --user start wlsunset
                fi
              ''}";
              on-click-right = "${pkgs.writeShellScript "waybar-nightlight-reset" ''
                ${pkgs.systemd}/bin/systemctl --user stop wlsunset-forced
                ${pkgs.systemd}/bin/systemctl --user restart wlsunset
              ''}";
            };

            "custom/caffeine" = {
              format = "{}";
              return-type = "json";
              interval = 2;
              exec = "${pkgs.writeShellScript "waybar-caffeine-status" ''
                if ${pkgs.systemd}/bin/systemctl --user is-active --quiet hypridle; then
                  echo '{"text":"󰾨","class":"inactive","tooltip":"Caffeine: Inactive (Screen locks after 3m)\nClick to keep screen awake"}'
                else
                  echo '{"text":"󰅶","class":"active","tooltip":"Caffeine: Active (Screen lock & sleep inhibited)\nClick to restore normal lock"}'
                fi
              ''}";
              on-click = "${pkgs.writeShellScript "waybar-caffeine-toggle" ''
                if ${pkgs.systemd}/bin/systemctl --user is-active --quiet hypridle; then
                  ${pkgs.systemd}/bin/systemctl --user stop hypridle
                  ${pkgs.libnotify}/bin/notify-send -u low -a "Caffeine" "Caffeine Active" "Idle lock screen and sleep inhibited."
                else
                  ${pkgs.systemd}/bin/systemctl --user start hypridle
                  ${pkgs.libnotify}/bin/notify-send -u low -a "Caffeine" "Caffeine Inactive" "Idle lock screen (3m) restored."
                fi
              ''}";
            };

            "custom/notification" = {
              tooltip = false;
              format = "{icon}";
              format-icons = {
                notification = "󱅫";
                none = "󰂚";
                dnd-notification = "󰂛";
                dnd-none = "󰂛";
                inhibited-notification = "󱅫";
                inhibited-none = "󰂚";
                dnd-inhibited-notification = "󰂛";
                dnd-inhibited-none = "󰂛";
              };
              return-type = "json";
              exec-if = "which swaync-client";
              exec = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
              on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
              on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
              escape = true;
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

          #custom-launcher {
            background-color: #202020;
            border: 1px solid #383838;
            border-radius: 6px;
            padding: 0 10px;
            margin: 4px 8px 4px 6px;
            color: #94a3b8;
            font-size: 11px;
            font-weight: 500;
          }

          #custom-launcher:hover {
            background-color: #2a2a2a;
            border-color: #555555;
            color: #ffffff;
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
          #custom-notification,
          #tray {
            padding: 0 10px;
            color: #e2e8f0;
          }

          #custom-nightlight {
            padding: 0 10px;
          }

          #custom-nightlight.auto {
            color: #34d399;
          }

          #custom-nightlight.on {
            color: #f59e0b;
          }

          #custom-nightlight.off {
            color: #64748b;
          }

          #custom-caffeine {
            padding: 0 10px;
          }

          #custom-caffeine.active {
            color: #34d399;
          }

          #custom-caffeine.inactive {
            color: #64748b;
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
