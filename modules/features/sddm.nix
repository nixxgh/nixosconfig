{ self, inputs, ... }: { 
  flake.nixosModules.sddm = { pkgs, lib, ... }: {
    services.displayManager.sddm = {
      enable = true;
    };
  };
} 
