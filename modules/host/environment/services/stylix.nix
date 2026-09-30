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

        # Derive palette and themes directly from the wallpaper snapshot
        image = ../../../../assets/wallpaper.png;
        polarity = "dark";

        # Opacity & transparency settings
        opacity = {
          terminal = 0.8;
          applications = 0.85;
          popups = 0.85;
          desktop = 0.85;
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
