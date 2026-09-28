{ self, inputs, ... }: {
  flake.homeModules.swaync =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.swaync = {
        enable = true;

        settings = {
          positionX = "right";
          positionY = "top";
          layer = "overlay";
          control-center-layer = "overlay";
          layer-shell = true;
          cssPriority = "application";
          control-center-margin-top = 10;
          control-center-margin-bottom = 10;
          control-center-margin-right = 10;
          control-center-margin-left = 10;
          notification-2fa-action = true;
          notification-inline-replies = true;
          notification-icon-size = 48;
          notification-body-image-height = 100;
          notification-body-image-width = 200;

          widgets = [
            "title"
            "dnd"
            "mpris"
            "notifications"
          ];

          widget-config = {
            title = {
              text = "Notifications";
              clear-all-button = true;
              button-text = "Clear All";
            };
            dnd = {
              text = "Do Not Disturb";
            };
            mpris = {
              image-size = 80;
              image-radius = 8;
            };
          };
        };

        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font", monospace;
            font-size: 13px;
          }

          .control-center {
            background: rgba(15, 23, 42, 0.95);
            border: 2px solid #10b981;
            border-radius: 12px;
            color: #f8fafc;
            padding: 12px;
          }

          .notification-row {
            outline: none;
            margin: 6px;
          }

          .notification {
            background: #1e293b;
            border: 1px solid #334155;
            border-radius: 8px;
            color: #f8fafc;
            padding: 10px;
          }

          .notification.critical {
            border: 2px solid #ef4444;
          }

          .notification-content {
            margin: 4px;
          }

          .summary {
            font-weight: bold;
            color: #34d399;
          }

          .body {
            color: #cbd5e1;
          }

          .widget-title {
            color: #f8fafc;
            font-weight: bold;
            font-size: 14px;
            margin: 6px;
          }

          .widget-title > button {
            background: #1e293b;
            color: #34d399;
            border: 1px solid #334155;
            border-radius: 6px;
            padding: 4px 10px;
          }

          .widget-title > button:hover {
            background: #10b981;
            color: #0f172a;
          }

          .widget-dnd {
            background: #1e293b;
            border: 1px solid #334155;
            border-radius: 8px;
            padding: 8px;
            margin: 6px;
          }

          .widget-dnd > switch:checked {
            background: #10b981;
          }
        '';
      };
    };
}
