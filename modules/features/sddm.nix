{ self, inputs, ... }: { 
  flake.nixosModules.sddm = { pkgs, lib, ... }: {
    services.xserver.enable = true;

    services.displayManager.sddm = {
      enable = true;
    };
  };
} 
