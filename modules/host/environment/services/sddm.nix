{ self, inputs, ... }: {
  flake.nixosModules.sddm = { config, pkgs, lib, ... }:
    let
      sddmTheme = (pkgs.sddm-astronaut.override {
        themeConfig = {
          Font = config.stylix.fonts.monospace.name;
          FontSize = "13";

          # Clock & Header
          HeaderTextColor = config.lib.stylix.colors.base06-hex;
          DateTextColor = config.lib.stylix.colors.base04-hex;
          TimeTextColor = config.lib.stylix.colors.base06-hex;

          # Background & Form Colors
          FormBackgroundColor = config.lib.stylix.colors.base00-hex;
          BackgroundColor = config.lib.stylix.colors.base00-hex;
          DimBackgroundColor = config.lib.stylix.colors.base00-hex;

          # Inputs
          LoginFieldBackgroundColor = config.lib.stylix.colors.base01-hex;
          PasswordFieldBackgroundColor = config.lib.stylix.colors.base01-hex;
          LoginFieldTextColor = config.lib.stylix.colors.base06-hex;
          PasswordFieldTextColor = config.lib.stylix.colors.base06-hex;
          UserIconColor = config.lib.stylix.colors.base06-hex;
          PasswordIconColor = config.lib.stylix.colors.base06-hex;
          PlaceholderTextColor = config.lib.stylix.colors.base04-hex;
          WarningColor = config.lib.stylix.colors.base08-hex;

          # Buttons & Controls
          LoginButtonTextColor = config.lib.stylix.colors.base00-hex;
          LoginButtonBackgroundColor = config.lib.stylix.colors.base09-hex;
          SystemButtonsIconsColor = config.lib.stylix.colors.base06-hex;
          SessionButtonTextColor = config.lib.stylix.colors.base06-hex;
          VirtualKeyboardButtonTextColor = config.lib.stylix.colors.base06-hex;

          # Dropdowns & Highlights
          DropdownTextColor = config.lib.stylix.colors.base06-hex;
          DropdownSelectedBackgroundColor = config.lib.stylix.colors.base02-hex;
          DropdownBackgroundColor = config.lib.stylix.colors.base01-hex;
          HighlightTextColor = config.lib.stylix.colors.base06-hex;
          HighlightBackgroundColor = config.lib.stylix.colors.base02-hex;
          HighlightBorderColor = config.lib.stylix.colors.base03-hex;

          # Hover States
          HoverUserIconColor = config.lib.stylix.colors.base0A-hex;
          HoverPasswordIconColor = config.lib.stylix.colors.base0A-hex;
          HoverSystemButtonsIconsColor = config.lib.stylix.colors.base0A-hex;
          HoverSessionButtonTextColor = config.lib.stylix.colors.base0A-hex;
          HoverVirtualKeyboardButtonTextColor = config.lib.stylix.colors.base0A-hex;

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

