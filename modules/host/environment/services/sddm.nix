{ self, inputs, ... }: {
  flake.nixosModules.sddm = { config, pkgs, lib, ... }:
    let
      sddmTheme = (pkgs.sddm-astronaut.override {
        themeConfig = {
          Font = config.stylix.fonts.monospace.name;
          FontSize = "13";

          # Clock & Header
          HeaderTextColor = self.theme.hex.text;
          DateTextColor = self.theme.hex.textMuted;
          TimeTextColor = self.theme.hex.text;

          # Background & Form Colors
          FormBackgroundColor = self.theme.hex.bg;
          BackgroundColor = self.theme.hex.bg;
          DimBackgroundColor = self.theme.hex.bg;

          # Inputs
          LoginFieldBackgroundColor = self.theme.hex.surface;
          PasswordFieldBackgroundColor = self.theme.hex.surface;
          LoginFieldTextColor = self.theme.hex.text;
          PasswordFieldTextColor = self.theme.hex.text;
          UserIconColor = self.theme.hex.text;
          PasswordIconColor = self.theme.hex.text;
          PlaceholderTextColor = self.theme.hex.textMuted;
          WarningColor = self.theme.hex.danger;

          # Buttons & Controls
          LoginButtonTextColor = self.theme.hex.bg;
          LoginButtonBackgroundColor = self.theme.hex.accent;
          SystemButtonsIconsColor = self.theme.hex.text;
          SessionButtonTextColor = self.theme.hex.text;
          VirtualKeyboardButtonTextColor = self.theme.hex.text;

          # Dropdowns & Highlights
          DropdownTextColor = self.theme.hex.text;
          DropdownSelectedBackgroundColor = self.theme.hex.surfaceElevated;
          DropdownBackgroundColor = self.theme.hex.surface;
          HighlightTextColor = self.theme.hex.text;
          HighlightBackgroundColor = self.theme.hex.surfaceElevated;
          HighlightBorderColor = self.theme.hex.border;

          # Hover States
          HoverUserIconColor = self.theme.hex.accentLight;
          HoverPasswordIconColor = self.theme.hex.accentLight;
          HoverSystemButtonsIconsColor = self.theme.hex.accentLight;
          HoverSessionButtonTextColor = self.theme.hex.accentLight;
          HoverVirtualKeyboardButtonTextColor = self.theme.hex.accentLight;

          # System Wallpaper
          Background = "Backgrounds/wallpaper.png";
        };
      }).overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          chmod u+w $out/share/sddm/themes/sddm-astronaut-theme/Backgrounds/
          ln -sf ${config.stylix.image} $out/share/sddm/themes/sddm-astronaut-theme/Backgrounds/wallpaper.png
        '';
      });
    in
    {
      services.xserver.enable = true;
      services.xserver.desktopManager.xterm.enable = false;

      environment.systemPackages = [ sddmTheme ];

      services.displayManager.sddm = {
        enable = true;
        theme = "sddm-astronaut-theme";
        extraPackages = with pkgs.kdePackages; [
          qtsvg
          qtmultimedia
          qtvirtualkeyboard
        ];
        settings = lib.optionalAttrs (config.stylix.cursor != null) {
          Theme = {
            CursorTheme = config.stylix.cursor.name;
            CursorSize = config.stylix.cursor.size;
          };
        };
      };
    };
}

