{ self, inputs, ... }: {
  flake.nixosModules.bluetooth = { pkgs, lib, config, ... }: {
    hardware.bluetooth = {
      enable = true;
      # Turned off so Noctalia can manage the state instead!
      powerOnBoot = false; 
      settings = {
        General = {
          Experimental = true; 
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
}
