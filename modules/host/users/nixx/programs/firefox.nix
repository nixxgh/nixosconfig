{ self, inputs, ... }: {
  flake.homeModules.firefox = { pkgs, ... }: {
    stylix.targets.firefox.profileNames = [ "default" ];

    programs.firefox = {
      enable = true;
      configPath = ".mozilla/firefox";
    };
  };
}
