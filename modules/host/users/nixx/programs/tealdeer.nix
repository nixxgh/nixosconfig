{ self, inputs, ... }: {
  flake.homeModules.tealdeer =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Fast Rust implementation of tldr (simplified community man pages)
      programs.tealdeer = {
        enable = true;
        enableAutoUpdates = true;
        settings = {
          updates = {
            auto_update = true;
          };
        };
      };
    };
}
