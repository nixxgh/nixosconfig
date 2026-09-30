{ self, inputs, ... }: {
  flake.homeModules.packages =
    { pkgs, ... }:
    {
      # User packages that do not require dedicated module configuration
      home.packages = with pkgs; [
        home-manager
        yt-dlp
        antigravity-cli
        grim
        slurp
        satty
        wl-clipboard
        libnotify
        pavucontrol
        mpvpaper
      ];
    };
}
