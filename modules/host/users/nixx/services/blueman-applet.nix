{ self, inputs, ... }: {
  flake.homeModules.bluemanApplet =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.blueman-applet.enable = true;

      dconf.settings."org/blueman/general" = {
        plugin-list = [ "!ConnectionNotifier" ];
      };
    };
}

