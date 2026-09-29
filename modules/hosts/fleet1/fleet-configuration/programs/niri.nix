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
    let
      screenshotQuick = pkgs.writeShellScript "screenshot-quick" ''
        GEOM=$(${pkgs.slurp}/bin/slurp -d -b "#00000080" -c "#10b981ff" -s "#00000000" -w 2) || exit 0
        [ -z "$GEOM" ] && exit 0
        DIR="$HOME/Pictures/Screenshots"
        mkdir -p "$DIR"
        FILE="$DIR/Screenshot_$(${pkgs.coreutils}/bin/date +'%Y-%m-%d_%H-%M-%S').png"
        ${pkgs.grim}/bin/grim -g "$GEOM" "$FILE"
        ${pkgs.wl-clipboard}/bin/wl-copy -t image/png < "$FILE"
        ${pkgs.libnotify}/bin/notify-send -i "$FILE" "Screenshot Captured" "Saved to $(basename "$FILE") & copied to clipboard" -a "Screenshot" -t 2000
      '';

      screenshotSatty = pkgs.writeShellScript "screenshot-satty" ''
        GEOM=$(${pkgs.slurp}/bin/slurp -d -b "#00000080" -c "#10b981ff" -s "#00000000" -w 2) || exit 0
        [ -z "$GEOM" ] && exit 0
        mkdir -p "$HOME/Pictures/Screenshots"
        ${pkgs.grim}/bin/grim -g "$GEOM" - | ${pkgs.satty}/bin/satty \
          --filename - \
          --fullscreen \
          --output-filename "$HOME/Pictures/Screenshots/Screenshot_%Y-%m-%d_%H-%M-%S.png" \
          --copy-command "${pkgs.wl-clipboard}/bin/wl-copy" \
          --actions-on-enter save-to-clipboard \
          --early-exit all
      '';

      toggleTealTerminal = pkgs.writeShellScript "toggle-teal-terminal" ''
        if ${pkgs.procps}/bin/pgrep -f "kitty --class floating-teal" > /dev/null; then
          ${pkgs.procps}/bin/pkill -f "kitty --class floating-teal"
        else
          RES=$(${pkgs.niri}/bin/niri msg --json outputs 2>/dev/null | ${pkgs.jq}/bin/jq -r 'to_entries[0].value.logical | "\(.width) \(.height)"' 2>/dev/null || echo "1366 768")
          W=$(echo "$RES" | ${pkgs.gawk}/bin/awk '{print $1 - 10}')
          H=$(echo "$RES" | ${pkgs.gawk}/bin/awk '{print $2 - 10}')
          ${pkgs.kitty}/bin/kitty \
            --class floating-teal \
            -o background=#042f2e \
            -o background_opacity=0.75 \
            -o background_blur=40 \
            -o remember_window_size=no \
            -o initial_window_width="''${W}" \
            -o initial_window_height="''${H}" \
            -o hide_window_decorations=yes \
            -o confirm_os_window_close=0 &
        fi
      '';
    in
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
            [ (lib.getExe pkgs.swaybg) "-c" "#000000" ]
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
            "background-color" = "#000000";
            "default-column-width".proportion = 1.0;
            focus-ring = {
              on = { };
              width = 2;
              active-color = "#5a5a5a";
              inactive-color = "#242424";
            };
          };

          window-rule = {
            open-maximized = true;
          };

          extraConfig = ''
            window-rule {
              match app-id="floating-teal"
              open-floating true
              default-floating-position x=5 y=5 relative-to="top-left"
            }
          '';

          binds = {
            "Mod+Return".spawn-sh = lib.getExe pkgs.alacritty;
            "Mod+B".spawn-sh = "${toggleTealTerminal}";
            "Mod+D".spawn-sh = "ags toggle bar";
            "Mod+S".spawn-sh = "ags toggle launcher";
            "Mod+Shift+S".spawn-sh = "${screenshotQuick}";
            "Print".spawn-sh = "${screenshotQuick}";
            "Mod+Alt+S".spawn-sh = "${screenshotSatty}";
            "Shift+Print".spawn-sh = "${screenshotSatty}";
            "Mod+N".spawn-sh = "ags toggle notifications";
            "Mod+Alt+L".spawn-sh = "loginctl lock-session";
            "Mod+Q".close-window = { };
            "Mod+Shift+Slash".show-hotkey-overlay = { };
            "Mod+Shift+E".quit = { };

            # Column & Workspace Focus (Vim HJKL)
            "Mod+H".focus-column-left = { };
            "Mod+L".focus-column-right = { };
            "Mod+K".focus-workspace-up = { };
            "Mod+J".focus-workspace-down = { };

            # Move Columns & Workspaces (Vim Ctrl / Shift + HJKL)
            "Mod+Ctrl+H".move-column-left = { };
            "Mod+Ctrl+L".move-column-right = { };
            "Mod+Ctrl+K".move-column-to-workspace-up = { };
            "Mod+Ctrl+J".move-column-to-workspace-down = { };
            "Mod+Shift+H".move-column-left = { };
            "Mod+Shift+L".move-column-right = { };
            "Mod+Shift+K".move-column-to-workspace-up = { };
            "Mod+Shift+J".move-column-to-workspace-down = { };

            "Mod+R".switch-preset-column-width = { };
            "Mod+F".maximize-column = { };
            "Mod+Comma".consume-or-expel-window-left = { };
            "Mod+Period".consume-or-expel-window-right = { };
            "Mod+Shift+F".toggle-window-floating = { };
            "Mod+Space".switch-focus-between-floating-and-tiling = { };
            "Mod+Tab".toggle-overview = { };

            # Media and Hardware Keys (Universal for Mac & PC keyboards)
            "XF86AudioRaiseVolume" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
            };
            "XF86AudioLowerVolume" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
            };
            "XF86AudioMute" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            };
            "XF86AudioMicMute" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            };
            "XF86MonBrightnessUp" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.brightnessctl}/bin/brightnessctl set 5%+";
            };
            "XF86MonBrightnessDown" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
            };
            "XF86AudioPlay" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.playerctl}/bin/playerctl play-pause";
            };
            "XF86AudioPause" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.playerctl}/bin/playerctl play-pause";
            };
            "XF86AudioNext" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.playerctl}/bin/playerctl next";
            };
            "XF86AudioPrev" = _: {
              props.allow-when-locked = true;
              content.spawn-sh = "${pkgs.playerctl}/bin/playerctl previous";
            };
          };
        };
      };
    };
}
