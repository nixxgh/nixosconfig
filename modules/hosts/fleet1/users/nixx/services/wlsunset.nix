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

      systemd.user.services.wlsunset = {
        Unit = {
          Conflicts = [ "wlsunset-forced.service" ];
          StartLimitIntervalSec = 0;
        };
        Install = {
          WantedBy = lib.mkForce [ ];
        };
      };

      systemd.user.services.wlsunset-forced = {
        Unit = {
          Description = "Forced warm night light (4000K locked)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Conflicts = [ "wlsunset.service" ];
          StartLimitIntervalSec = 0;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.wlsunset}/bin/wlsunset -l 19.07 -L 72.87 -t 4000 -T 4001";
          Restart = "on-failure";
        };
      };
    };
}
