{ self, inputs, ... }: {
  flake.nixosModules.stylix =
    { pkgs, lib, ... }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
      ];

      stylix = {
        enable = true;
        autoEnable = true;

        # Derive palette and styling from Gruvbox Dark Hard
        image = ../../../../assets/wallpaper.png;
        polarity = "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

        # Opacity & transparency settings
        opacity = {
          terminal = 0.7;
          applications = 0.8;
          popups = 0.8;
          desktop = 0.8;
        };

        # Fonts
        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font";
          };
          sansSerif = {
            package = pkgs.dejavu_fonts;
            name = "DejaVu Sans";
          };
          serif = {
            package = pkgs.dejavu_fonts;
            name = "DejaVu Serif";
          };
          sizes = {
            terminal = 12;
            applications = 11;
            popups = 11;
            desktop = 10;
          };
        };

        # Disable Stylix's static wallpaper managers and hyprlock override
        targets = {
          feh.enable = false;
          gnome.enable = false;
        };
      };
    };
}
