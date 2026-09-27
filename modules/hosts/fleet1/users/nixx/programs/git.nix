{ self, inputs, ... }: {
  flake.homeModules.git = { pkgs, ... }: {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "nixxgh";
          email = "275239900+nixxgh@users.noreply.github.com";
        };
        init.defaultBranch = "main";
      };
    };

    programs.gh = {
      enable = true;
    };
  };
}
