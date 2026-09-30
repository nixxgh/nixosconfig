{ self, inputs, ... }: {
  flake.nixosModules.sddm = { pkgs, lib, ... }: {
    services.xserver.enable = true;
    services.xserver.desktopManager.xterm.enable = false;

    services.displayManager.sddm = {
      enable = true;
    };
  };
}
