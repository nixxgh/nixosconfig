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
            gradient_color_1 = "'#10b981'";
            gradient_color_2 = "'#14b8a6'";
            gradient_color_3 = "'#06b6d4'";
          };
        };
      };
    };
}
