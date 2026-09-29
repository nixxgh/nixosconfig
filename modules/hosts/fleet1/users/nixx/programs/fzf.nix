{ self, inputs, ... }: {
  flake.homeModules.fzf =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
