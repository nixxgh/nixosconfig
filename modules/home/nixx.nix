{ self, inputs, ... }: {
  flake.homeModules.nixx = { config, pkgs, lib, ... }: {
    home.username = "nixx";
    home.homeDirectory = "/home/nixx";
    home.stateVersion = "24.11";

    # Let Home Manager manage itself
    programs.home-manager.enable = true;

    # User packages moved from configuration.nix
    home.packages = with pkgs; [
      yt-dlp
      antigravity-cli
    ];

    # Git configuration (modern Home Manager syntax)
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

    # GitHub CLI
    programs.gh = {
      enable = true;
    };
  };
}
