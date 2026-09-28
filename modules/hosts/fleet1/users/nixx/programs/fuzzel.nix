{ self, inputs, ... }: {
  flake.homeModules.fuzzel =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            font = "JetBrainsMono Nerd Font:size=13";
            prompt = "\"❯ \"";
            icons-enabled = true;
            terminal = "${pkgs.alacritty}/bin/alacritty";
            layer = "overlay";
            width = 35;
            lines = 10;
            horizontal-pad = 20;
            vertical-pad = 14;
            inner-pad = 8;
          };

          colors = {
            background = "1a1a1aff"; # Charcoal 900
            text = "f8fafcff";       # White text
            match = "34d399ff";      # Emerald 400
            selection = "2c2c2cff";  # Charcoal selection
            selection-text = "10b981ff"; # Emerald 500
            selection-match = "34d399ff";
            border = "5a5a5aff";     # Charcoal grey border
          };

          border = {
            width = 2;
            radius = 12;
          };
        };
      };
    };
}
