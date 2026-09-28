{ self, inputs, ... }: {
  flake.homeModules.nmApplet =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.network-manager-applet.enable = true;
    };
}
