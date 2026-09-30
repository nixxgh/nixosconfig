{ self, inputs, ... }: {
  flake.homeModules.fuzzel =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      hideDesktopEntry = name: {
        "applications/${name}.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=${name}
          NoDisplay=true
        '';
      };
    in
    {
      # Suppress secondary utilities and background daemons from application launcher
      xdg.dataFile = lib.mkMerge [
        (hideDesktopEntry "xterm")
        (hideDesktopEntry "nixos-manual")
        (hideDesktopEntry "blueman-adapters")
        (hideDesktopEntry "nm-connection-editor")
        (hideDesktopEntry "dev.lizardbyte.app.Sunshine")
        (hideDesktopEntry "dev.lizardbyte.app.Sunshine.kwin")
        (hideDesktopEntry "dev.lizardbyte.app.Sunshine.terminal")
        (hideDesktopEntry "nvim")
      ];

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
