{ self, inputs, ... }: {
  flake.homeModules.hyprlock =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            disable_loading_bar = true;
            grace = 0;
            hide_cursor = false;
          };

          background = [
            {
              path = "screenshot";
              blur_passes = 3;
              blur_size = 8;
              color = "rgb(15, 23, 42)";
            }
          ];

          input-field = [
            {
              size = "250, 50";
              outline_thickness = 2;
              dots_size = 0.25;
              dots_spacing = 0.5;
              dots_center = true;
              outer_color = "rgb(16, 185, 129)";
              inner_color = "rgb(30, 41, 59)";
              font_color = "rgb(248, 250, 252)";
              fade_on_empty = false;
              placeholder_text = "<i>Enter Password...</i>";
              hide_input = false;
              check_color = "rgb(52, 211, 153)";
              fail_color = "rgb(239, 68, 68)";
              fail_text = "<i>Authentication Failed</i>";
              position = "0, -80";
              halign = "center";
              valign = "center";
            }
          ];

          label = [
            {
              text = "$TIME";
              color = "rgb(248, 250, 252)";
              font_size = 64;
              font_family = "JetBrainsMono Nerd Font Bold";
              position = "0, 100";
              halign = "center";
              valign = "center";
            }
            {
              text = "cmd[update:1000] echo \"$(date +\"%A, %B %d\")\"";
              color = "rgb(52, 211, 153)";
              font_size = 18;
              font_family = "JetBrainsMono Nerd Font";
              position = "0, 30";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };
    };
}
