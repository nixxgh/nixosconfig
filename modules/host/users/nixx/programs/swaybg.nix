{ self, inputs, ... }: {
  flake.homeModules.swaybg =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = with pkgs; [
        swaybg
      ];
    };
}
