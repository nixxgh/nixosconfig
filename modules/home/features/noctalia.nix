{ self, inputs, ... }: {

  flake.homeModules.noctalia =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      programs.noctalia = {
        enable = true;

        settings = {
          bar.default = {
            position = "bottom";
          };

          theme = {
            builtin = "Ayu";
            community_palette = "Ayu Blue";
            mode = "dark";
            source = "builtin";
            wallpaper_scheme = "m3-content";
          };

          wallpaper.default.path = "color:#000000";
          wallpaper.last.path = "color:#000000";
          wallpaper.monitors.eDP-1.path = "color:#000000";

          location.auto_locate = true;

          nightlight = {
            enabled = true;
            force = true;
          };

          idle = {
            behavior_order = [ "lock" "screen-off" "lock-and-suspend" ];
            pre_action_fade_seconds = 2.0;

            behavior = {
              lock = {
                action = "lock";
                command = "";
                enabled = true;
                locked_timeout = 0.0;
                resume_command = "";
                timeout = 180.0;
              };
              screen-off = {
                action = "screen_off";
                command = "";
                enabled = true;
                locked_timeout = 60.0;
                resume_command = "";
                timeout = 0.0;
              };
              lock-and-suspend = {
                action = "lock_and_suspend";
                command = "";
                enabled = false;
                locked_timeout = 0.0;
                resume_command = "";
                timeout = 900.0;
              };
            };
          };

          lockscreen_widgets = {
            enabled = false;
            schema_version = 2;
            widget_order = [ "lockscreen-login-box@eDP-1" ];

            grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };

            widget."lockscreen-login-box@eDP-1" = {
              type = "login_box";
              output = "eDP-1";
              box_width = 810.0;
              box_height = 196.0;
              cx = 683.0;
              cy = 586.0;
              placement_width = 1366.0;
              placement_height = 768.0;
              rotation = 0.0;

              settings = {
                background_color = "surface_variant";
                background_opacity = 0.88;
                background_radius = 12.0;
                center_password_text = false;
                input_opacity = 1.0;
                input_radius = 6.0;
                layout = "regular";
                show_caps_lock = true;
                show_keyboard_layout = true;
                show_login_button = true;
                show_media = true;
                show_session_buttons = true;
                show_unlock_hint = true;
                show_weather = true;
              };
            };
          };
        };
      };
    };

  # Expose the Noctalia package for Niri to reference in spawn-at-startup
  perSystem = { pkgs, ... }: {
    packages.myNoctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

}
