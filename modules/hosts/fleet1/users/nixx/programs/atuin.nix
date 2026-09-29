{ self, inputs, ... }: {
  flake.homeModules.atuin =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        flags = [ "--disable-up-arrow" ];
        settings = {
          search_mode = "fuzzy";
          style = "compact";
          inline_height = 20;
          show_preview = true;
        };
      };
    };
}
