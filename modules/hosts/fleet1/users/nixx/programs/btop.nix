{ self, inputs, ... }: {
  flake.homeModules.btop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.btop = {
        enable = true;
        settings = {
          color_theme = "Default";
          theme_background = false; # Respect terminal background transparency
          vim_keys = true;
          update_ms = 1000;
        };
      };
    };
}
