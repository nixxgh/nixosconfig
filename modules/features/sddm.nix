{ self, inputs, ... }: { 
  flake.nixosModules.sddm = { pkgs, lib, ... }: {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
      #package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
  };
} 
