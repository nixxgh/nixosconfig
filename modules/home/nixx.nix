{ self, inputs, ... }: {
  flake.homeModules.nixx = { config, pkgs, lib, ... }: {
    imports = [
      self.homeModules.git
      self.homeModules.neovim
      self.homeModules.firefox
    ];

    home.username = "nixx";
    home.homeDirectory = "/home/nixx";
    home.stateVersion = "24.11";

    # Let Home Manager manage itself
    programs.home-manager.enable = true;

    # General user utilities
    home.packages = with pkgs; [
      yt-dlp
      antigravity-cli
    ];
  };
}
