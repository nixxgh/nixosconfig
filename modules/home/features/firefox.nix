{ self, inputs, ... }: {
  flake.homeModules.firefox = { pkgs, ... }: {
    programs.firefox = {
      enable = true;
    };
  };
}
