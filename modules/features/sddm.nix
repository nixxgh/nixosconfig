{ self, inputs, ... }: { 
  flake.nixosModules.sddm = { pkgs, lib, ... }: {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;

      settings = {
        Wayland = {
          # Tell SDDM to launch Weston using a config file generated in the Nix store
          CompositorCommand = "weston --shell=fullscreen-shell.so --config ${pkgs.writeText \"sddm-weston.ini\" ''
            [libinput]
            enable-tap=true
          ''}";
        };
    };
  };
} 
