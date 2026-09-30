{ self, inputs, ... }: {
  flake.homeModules.hyprlock =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      stylix.targets.hyprlock.enable = false;

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
              color = self.theme.rgb.surfaceMuted;
            }
          ];

          input-field = [
            {
              size = "250, 50";
              outline_thickness = 2;
              dots_size = 0.25;
              dots_spacing = 0.5;
              dots_center = true;
              outer_color = self.theme.rgb.accent;
              inner_color = self.theme.rgb.surfaceBorder;
              font_color = self.theme.rgb.text;
              fade_on_empty = false;
              placeholder_text = "<i>Enter Password...</i>";
              hide_input = false;
              check_color = self.theme.rgb.accentLight;
              fail_color = self.theme.rgb.danger;
              fail_text = "<i>Authentication Failed</i>";
              position = "0, -80";
              halign = "center";
              valign = "center";
            }
          ];

          label = [
            {
              text = "$TIME";
              color = self.theme.rgb.text;
              font_size = 64;
              font_family = "JetBrainsMono Nerd Font Bold";
              position = "0, 100";
              halign = "center";
              valign = "center";
            }
            {
              text = "cmd[update:1000] echo \"$(date +\"%A, %B %d\")\"";
              color = self.theme.rgb.accentLight;
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
