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
            background = "${self.theme.raw.surface}ff";
            text = "${self.theme.raw.text}ff";
            match = "${self.theme.raw.accentLight}ff";
            selection = "${self.theme.raw.surfaceElevated}ff";
            selection-text = "${self.theme.raw.accent}ff";
            selection-match = "${self.theme.raw.accentLight}ff";
            border = "${self.theme.raw.border}ff";
          };

          border = {
            width = 2;
            radius = 12;
          };
        };
      };
    };
}
