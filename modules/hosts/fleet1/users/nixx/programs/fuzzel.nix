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
            background = "0f172aff"; # Slate 900
            text = "f8fafcff";       # Slate 50
            match = "34d399ff";      # Emerald 400
            selection = "1e293bff";  # Slate 800
            selection-text = "10b981ff"; # Emerald 500
            selection-match = "34d399ff";
            border = "10b981ff";     # Emerald 500 border
          };

          border = {
            width = 2;
            radius = 12;
          };
        };
      };
    };
}
