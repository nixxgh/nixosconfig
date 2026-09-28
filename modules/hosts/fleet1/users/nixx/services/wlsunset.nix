{ self, inputs, ... }: {
  flake.homeModules.wlsunset =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.wlsunset = {
        enable = true;
        latitude = "19.07";
        longitude = "72.87";
        temperature = {
          day = 6500;
          night = 4000;
        };
      };

      systemd.user.services.wlsunset-forced = {
        Unit = {
          Description = "Forced warm night light (4000K locked)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${pkgs.wlsunset}/bin/wlsunset -l 19.07 -L 72.87 -t 4000 -T 4000";
          Restart = "on-failure";
        };
      };
    };
}
