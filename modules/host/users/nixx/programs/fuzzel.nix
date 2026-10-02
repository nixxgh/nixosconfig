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
        (hideDesktopEntry "dev.lizardbyte.app.Sunshine")
        (hideDesktopEntry "dev.lizardbyte.app.Sunshine.kwin")
        (hideDesktopEntry "dev.lizardbyte.app.Sunshine.terminal")
        (hideDesktopEntry "nvim")
        (hideDesktopEntry "kvantummanager")
        (hideDesktopEntry "qt5ct")
        (hideDesktopEntry "qt6ct")
        {
          "applications/nmtui.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=Wi-Fi & Networks
            Comment=Manage Wi-Fi and network connections
            Exec=${pkgs.alacritty}/bin/alacritty -e ${pkgs.networkmanager}/bin/nmtui
            Icon=network-wireless
            Terminal=false
            Categories=Settings;Network;
          '';
        }
      ];

      stylix.targets.rofi.enable = false;

      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
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

          border = {
            width = 2;
            radius = 12;
          };
        };
      };
    };
}
