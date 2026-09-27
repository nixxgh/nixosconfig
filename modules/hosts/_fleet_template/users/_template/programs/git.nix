{ self, inputs, ... }: {
  flake.homeModules.git =
    { pkgs, ... }:
    {
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = "Your Name";
            email = "your.email@example.com";
          };
          init.defaultBranch = "main";
        };
      };
    };
}
