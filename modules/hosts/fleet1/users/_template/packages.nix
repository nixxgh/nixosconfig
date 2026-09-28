{ self, inputs, ... }: {
  flake.homeModules.packages =
    { pkgs, ... }:
    {
      # User packages that do not require dedicated module configuration
      home.packages = with pkgs; [
        # Add personal user CLI tools here (e.g. ripgrep, bat)
        grim
        slurp
        satty
        wl-clipboard
        libnotify
        pavucontrol
      ];
    };
}
