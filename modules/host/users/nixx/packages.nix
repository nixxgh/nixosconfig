{ self, inputs, ... }: {
  flake.homeModules.packages =
    { pkgs, ... }:
    let
      caffeine = pkgs.writeShellScriptBin "caffeine" ''
        if [ "$1" = "status" ]; then
          if ${pkgs.systemd}/bin/systemctl --user is-active --quiet hypridle; then
            echo "caffeine stopped"
          else
            echo "caffeine started"
          fi
          exit 0
        fi

        if ${pkgs.systemd}/bin/systemctl --user is-active --quiet hypridle; then
          ${pkgs.systemd}/bin/systemctl --user stop hypridle
          echo "caffeine started"
        else
          ${pkgs.systemd}/bin/systemctl --user start hypridle
          echo "caffeine stopped"
        fi
      '';
    in
    {
      # User packages that do not require dedicated module configuration
      home.packages = with pkgs; [
        caffeine
        yt-dlp
        antigravity-cli
        grim
        slurp
        satty
        wl-clipboard
        libnotify
        pavucontrol
        mpvpaper
        google-chrome
        firefox
        vscode
      ];
    };
}
