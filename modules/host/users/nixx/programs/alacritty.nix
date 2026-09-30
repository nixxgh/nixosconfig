{ self, inputs, ... }: {
  flake.homeModules.alacritty =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      esc = builtins.fromJSON "\"\\u001b\"";
    in
    {
      programs.alacritty = {
        enable = true;
        settings = {
          colors = {
            primary = {
              background = self.theme.hex.bg;
            };
          };

          window.opacity = 0.75;

          keyboard.bindings = [
            {
              key = "Return";
              mods = "Shift";
              chars = "${esc}[13;2u";
            }
          ];
        };
      };
    };
}
