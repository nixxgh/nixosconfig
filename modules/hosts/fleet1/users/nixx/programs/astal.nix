{ self, inputs, ... }: {
  flake.homeModules.astal =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.ags.homeManagerModules.default
      ];

      programs.ags = {
        enable = true;
        configDir = ./astal;
        systemd.enable = true;
      };
    };
}
