{ self, inputs, ... }: {
  
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };
  

  perSystem = { pkgs, lib, self', ... }: {
    
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      settings = {
        hotkey-overlay.skip-at-startup = true;
         
        spawn-at-startup = [
          (lib.getExe self'.packages.myNoctalia)
        ];

	xwayland-satellite.path = 
	  lib.getExe pkgs.xwayland-satellite;
      
        input.keyboard = {
          xkb.layout = "us,ua";
        };
           
        layout.gaps = 5;
        layout."background-color" = "#000000";
       
        binds = {
          "Mod+S".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
          "Mod+Return".spawn-sh = lib.getExe pkgs.alacritty;
          "Mod+Q".close-window = {};
          "Mod+Shift+Slash".show-hotkey-overlay = {};
          "Mod+Shift+E".quit = {};
          "Mod+Left".focus-column-left = {};
          "Mod+Right".focus-column-right = {};
          "Mod+Up".focus-workspace-up = {};
          "Mod+Down".focus-workspace-down = {};
          "Mod+Ctrl+Left".move-column-left = {};
          "Mod+Ctrl+Right".move-column-right = {};
          "Mod+Ctrl+up".move-column-to-workspace-up = {};
          "Mod+Ctrl+down".move-column-to-workspace-down = {};
          "Mod+R".switch-preset-column-width = {};
          "Mod+F".maximize-column = {};
          "Mod+Comma".consume-or-expel-window-left = {};
          "Mod+Period".consume-or-expel-window-right = {};
          "Mod+Shift+F".toggle-window-floating = {};
          "Mod+Space".switch-focus-between-floating-and-tiling = {};
          "Mod+Tab".toggle-overview = {};
          
        };
      };
    };
  };
}
