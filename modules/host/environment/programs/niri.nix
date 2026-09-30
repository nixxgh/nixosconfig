{ self, inputs, ... }: {

  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };

  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {

      packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          prefer-no-csd = { };
          hotkey-overlay.skip-at-startup = true;

          gestures = {
            hot-corners = {
              off = { };
            };
          };

          spawn-at-startup = [
            [
              (lib.getExe pkgs.mpvpaper)
              "-p"
              "-o"
              "no-audio loop hwdec=auto"
              "*"
              "/home/nixx/Pictures/Wallpapers/the-bridge-under-the-northern-lights-moewalls-com.mp4"
            ]
          ];

          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          input = {
            keyboard = {
              xkb.layout = "us,ua";
            };
            touchpad = {
              tap = { };
            };
          };

          layout = {
            gaps = 5;
            "background-color" = "transparent";
            focus-ring = {
              on = { };
              width = 2;
              active-color = self.theme.hex.accent;
              inactive-color = self.theme.hex.borderInactive;
            };
            border = {
              on = { };
              active-color = self.theme.hex.surfaceBorder;
              inactive-color = self.theme.hex.surfaceMuted;
            };
          };

          extraConfig = ''
            layer-rule {
              match namespace="^mpvpaper$"
              place-within-backdrop true
            }

            layer-rule {
              match namespace="^swaybg$"
              place-within-backdrop true
            }

            window-rule {
              match app-id="Alacritty"
              draw-border-with-background false
              clip-to-geometry true
              geometry-corner-radius 10
            }
          '';

          binds = {
            # Shows hotkey overlay
            "Mod+Shift+Slash".show-hotkey-overlay = _: { };

            # Suggested binds for running programs: terminal, app launcher, screen locker.
            "Mod+T" = _: {
              props.hotkey-overlay-title = "Open a Terminal: alacritty";
              content.spawn = lib.getExe pkgs.alacritty;
            };
            "Mod+D" = _: {
              props.hotkey-overlay-title = "Run an Application: fuzzel";
              content.spawn-sh = "pkill -x fuzzel || ${lib.getExe pkgs.fuzzel}";
            };
            "Super+Alt+L" = _: {
              props.hotkey-overlay-title = "Lock the Screen: hyprlock";
              content.spawn = "${pkgs.hyprlock}/bin/hyprlock";
            };

            # Screen reader
            "Super+Alt+S" = _: {
              props.allow-when-locked = true;
              props.hotkey-overlay-title = null;
              content.spawn-sh = "pkill orca || exec orca";
            };

            # PipeWire & WirePlumber Audio Keys
            "XF86AudioRaiseVolume" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
            };
            "XF86AudioLowerVolume" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
            };
            "XF86AudioMute" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            };
            "XF86AudioMicMute" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            };

            # Media Keys (Playerctl)
            "XF86AudioPlay" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.playerctl}/bin/playerctl play-pause";
            };
            "XF86AudioPause" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.playerctl}/bin/playerctl play-pause";
            };
            "XF86AudioStop" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.playerctl}/bin/playerctl stop";
            };
            "XF86AudioPrev" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.playerctl}/bin/playerctl previous";
            };
            "XF86AudioNext" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.playerctl}/bin/playerctl next";
            };

            # Brightness Keys (Brightnessctl)
            "XF86MonBrightnessUp" = _: {
              props.allow-when-locked = true;
              content.spawn = [ "${pkgs.brightnessctl}/bin/brightnessctl" "--class=backlight" "set" "+10%" ];
            };
            "XF86MonBrightnessDown" = _: {
              props.allow-when-locked = true;
              content.spawn = [ "${pkgs.brightnessctl}/bin/brightnessctl" "--class=backlight" "set" "10%-" ];
            };

            # Overview & Window Management
            "Mod+O" = _: {
              props.repeat = false;
              content.toggle-overview = _: { };
            };
            "Mod+Q" = _: {
              props.repeat = false;
              content.close-window = _: { };
            };

            # Focus Columns and Windows (Arrows + HJKL)
            "Mod+Left".focus-column-left = _: { };
            "Mod+Down".focus-window-down = _: { };
            "Mod+Up".focus-window-up = _: { };
            "Mod+Right".focus-column-right = _: { };
            "Mod+H".focus-column-left = _: { };
            "Mod+J".focus-window-down = _: { };
            "Mod+K".focus-window-up = _: { };
            "Mod+L".focus-column-right = _: { };

            # Move Columns and Windows (Arrows + HJKL)
            "Mod+Ctrl+Left".move-column-left = _: { };
            "Mod+Ctrl+Down".move-window-down = _: { };
            "Mod+Ctrl+Up".move-window-up = _: { };
            "Mod+Ctrl+Right".move-column-right = _: { };
            "Mod+Ctrl+H".move-column-left = _: { };
            "Mod+Ctrl+J".move-window-down = _: { };
            "Mod+Ctrl+K".move-window-up = _: { };
            "Mod+Ctrl+L".move-column-right = _: { };

            # Focus & Move First / Last Column
            "Mod+Home".focus-column-first = _: { };
            "Mod+End".focus-column-last = _: { };
            "Mod+Ctrl+Home".move-column-to-first = _: { };
            "Mod+Ctrl+End".move-column-to-last = _: { };

            # Monitor Focus (Arrows + HJKL)
            "Mod+Shift+Left".focus-monitor-left = _: { };
            "Mod+Shift+Down".focus-monitor-down = _: { };
            "Mod+Shift+Up".focus-monitor-up = _: { };
            "Mod+Shift+Right".focus-monitor-right = _: { };
            "Mod+Shift+H".focus-monitor-left = _: { };
            "Mod+Shift+J".focus-monitor-down = _: { };
            "Mod+Shift+K".focus-monitor-up = _: { };
            "Mod+Shift+L".focus-monitor-right = _: { };

            # Move Column to Monitor (Arrows + HJKL)
            "Mod+Shift+Ctrl+Left".move-column-to-monitor-left = _: { };
            "Mod+Shift+Ctrl+Down".move-column-to-monitor-down = _: { };
            "Mod+Shift+Ctrl+Up".move-column-to-monitor-up = _: { };
            "Mod+Shift+Ctrl+Right".move-column-to-monitor-right = _: { };
            "Mod+Shift+Ctrl+H".move-column-to-monitor-left = _: { };
            "Mod+Shift+Ctrl+J".move-column-to-monitor-down = _: { };
            "Mod+Shift+Ctrl+K".move-column-to-monitor-up = _: { };
            "Mod+Shift+Ctrl+L".move-column-to-monitor-right = _: { };

            # Workspace Navigation
            "Mod+Page_Down".focus-workspace-down = _: { };
            "Mod+Page_Up".focus-workspace-up = _: { };
            "Mod+U".focus-workspace-down = _: { };
            "Mod+I".focus-workspace-up = _: { };
            "Mod+Ctrl+Page_Down".move-column-to-workspace-down = _: { };
            "Mod+Ctrl+Page_Up".move-column-to-workspace-up = _: { };
            "Mod+Ctrl+U".move-column-to-workspace-down = _: { };
            "Mod+Ctrl+I".move-column-to-workspace-up = _: { };

            "Mod+Shift+Page_Down".move-workspace-down = _: { };
            "Mod+Shift+Page_Up".move-workspace-up = _: { };
            "Mod+Shift+U".move-workspace-down = _: { };
            "Mod+Shift+I".move-workspace-up = _: { };

            # Mouse Wheel Scroll with Cooldown
            "Mod+WheelScrollDown" = _: {
              props.cooldown-ms = 150;
              content.focus-workspace-down = _: { };
            };
            "Mod+WheelScrollUp" = _: {
              props.cooldown-ms = 150;
              content.focus-workspace-up = _: { };
            };
            "Mod+Ctrl+WheelScrollDown" = _: {
              props.cooldown-ms = 150;
              content.move-column-to-workspace-down = _: { };
            };
            "Mod+Ctrl+WheelScrollUp" = _: {
              props.cooldown-ms = 150;
              content.move-column-to-workspace-up = _: { };
            };

            "Mod+WheelScrollRight".focus-column-right = _: { };
            "Mod+WheelScrollLeft".focus-column-left = _: { };
            "Mod+Ctrl+WheelScrollRight".move-column-right = _: { };
            "Mod+Ctrl+WheelScrollLeft".move-column-left = _: { };

            "Mod+Shift+WheelScrollDown".focus-column-right = _: { };
            "Mod+Shift+WheelScrollUp".focus-column-left = _: { };
            "Mod+Ctrl+Shift+WheelScrollDown".move-column-right = _: { };
            "Mod+Ctrl+Shift+WheelScrollUp".move-column-left = _: { };

            # Workspaces 1-9
            "Mod+1".focus-workspace = 1;
            "Mod+2".focus-workspace = 2;
            "Mod+3".focus-workspace = 3;
            "Mod+4".focus-workspace = 4;
            "Mod+5".focus-workspace = 5;
            "Mod+6".focus-workspace = 6;
            "Mod+7".focus-workspace = 7;
            "Mod+8".focus-workspace = 8;
            "Mod+9".focus-workspace = 9;

            "Mod+Ctrl+1".move-column-to-workspace = 1;
            "Mod+Ctrl+2".move-column-to-workspace = 2;
            "Mod+Ctrl+3".move-column-to-workspace = 3;
            "Mod+Ctrl+4".move-column-to-workspace = 4;
            "Mod+Ctrl+5".move-column-to-workspace = 5;
            "Mod+Ctrl+6".move-column-to-workspace = 6;
            "Mod+Ctrl+7".move-column-to-workspace = 7;
            "Mod+Ctrl+8".move-column-to-workspace = 8;
            "Mod+Ctrl+9".move-column-to-workspace = 9;

            # Consume and Expel Windows
            "Mod+BracketLeft".consume-or-expel-window-left = _: { };
            "Mod+BracketRight".consume-or-expel-window-right = _: { };
            "Mod+Comma".consume-window-into-column = _: { };
            "Mod+Period".expel-window-from-column = _: { };

            # Column Presets & Heights
            "Mod+R".switch-preset-column-width = _: { };
            "Mod+Shift+R".switch-preset-column-width-back = _: { };
            "Mod+Ctrl+Shift+R".switch-preset-window-height = _: { };
            "Mod+Ctrl+R".reset-window-height = _: { };

            # Maximize & Fullscreen
            "Mod+F".maximize-column = _: { };
            "Mod+Shift+F".fullscreen-window = _: { };
            "Mod+M".maximize-window-to-edges = _: { };
            "Mod+Ctrl+F".expand-column-to-available-width = _: { };

            # Center Column
            "Mod+C".center-column = _: { };
            "Mod+Ctrl+C".center-visible-columns = _: { };

            # Fine Width & Height Adjustments
            "Mod+Minus".set-column-width = "-10%";
            "Mod+Equal".set-column-width = "+10%";
            "Mod+Shift+Minus".set-window-height = "-10%";
            "Mod+Shift+Equal".set-window-height = "+10%";

            # Floating Windows
            "Mod+V".toggle-window-floating = _: { };
            "Mod+Shift+V".switch-focus-between-floating-and-tiling = _: { };

            # Tabbed Column Display
            "Mod+W".toggle-column-tabbed-display = _: { };

            # Screenshots
            "Mod+Shift+S" = _: {
              props.hotkey-overlay-title = "Screenshot Region: grim + slurp";
              content.spawn-sh = "grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png";
            };
            "Mod+Alt+S" = _: {
              props.hotkey-overlay-title = "Screenshot Region → Satty";
              content.spawn-sh = "grim -g \"$(slurp)\" - | satty --filename - --output-filename ~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png";
            };

            # Native Screenshots

            "Print".screenshot = _: { };
            "Ctrl+Print".screenshot-screen = _: { };
            "Alt+Print".screenshot-window = _: { };

            # Shortcuts Inhibitor Toggle
            "Mod+Escape" = _: {
              props.allow-inhibiting = false;
              content.toggle-keyboard-shortcuts-inhibit = _: { };
            };

            # Session Quit & Monitor Control
            "Mod+Shift+E".quit = _: { };
            "Ctrl+Alt+Delete".quit = _: { };
            "Mod+Shift+P".power-off-monitors = _: { };
          };
        };
      };
    };
}
