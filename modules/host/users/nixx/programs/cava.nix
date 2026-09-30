{ self, inputs, ... }: {
  flake.homeModules.cava =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Console-based Audio Visualizer
      programs.cava = {
        enable = true;
        settings = {
          general.framerate = 60;
          input.method = "pipewire";
          smoothing.noise_reduction = 77;
          color = {
            background = "'default'";
            gradient = 1;
            gradient_count = 3;
            gradient_color_1 = "'${self.theme.hex.accent}'";
            gradient_color_2 = "'${self.theme.hex.accentLight}'";
            gradient_color_3 = "'${self.theme.hex.accentTeal}'";
          };
        };
      };
    };
}
