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
