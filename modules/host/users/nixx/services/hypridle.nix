{ self, inputs, ... }: {
  flake.homeModules.hypridle =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.hypridle = {
        enable = true;

        settings = {
          general = {
            lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "niri msg action power-on-monitors";
          };

          listener = [
            # 1. When manually locked (Mod+Alt+L): turn off display after 1 minute (60s) of inactivity
            {
              timeout = 60;
              on-timeout = "pidof hyprlock && niri msg action power-off-monitors";
              on-resume = "niri msg action power-on-monitors";
            }
            # 2. When unlocked: auto-lock session after 3 minutes (180s) of inactivity
            {
              timeout = 180;
              on-timeout = "loginctl lock-session";
            }
            # 3. 1 minute after auto-lock (180s + 60s = 240s): turn off display (DPMS sleep)
            {
              timeout = 240;
              on-timeout = "niri msg action power-off-monitors";
              on-resume = "niri msg action power-on-monitors";
            }
          ];
        };
      };
    };
}
