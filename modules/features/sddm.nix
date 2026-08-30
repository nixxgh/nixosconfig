{ self, inputs, ... }: { 
  flake.nixosModules.sddm = { pkgs, lib, ... }: {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;

      settings = {
        Wayland = {
          # Notice how it is just "sddm-weston.ini" now, without the backslashes!
          CompositorCommand = "weston --shell=fullscreen-shell.so --config ${pkgs.writeText "sddm-weston.ini" ''
            [libinput]
            enable-tap=true
          ''}";
        };
      };   
    };
  };
} 
