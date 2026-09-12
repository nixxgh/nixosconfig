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

	gestures = {
          hot-corners = {
            off = {};
          };
        };
         
        spawn-at-startup = [
          (lib.getExe self'.packages.myNoctalia)
        ];

	xwayland-satellite.path = 
	  lib.getExe pkgs.xwayland-satellite;
      
        input = {
	  keyboard = {
              xkb.layout = "us,ua";
            };
	  touchpad = {
	      tap = {};
	    };
	}; 
           
        layout = {
          gaps = 5;
          "background-color" = "#000000";
          "default-column-width".proportion = 1.0;
          focus-ring = {
            on = {};
            width = 2;
            active-color = "#6c7086";
            inactive-color = "#313244";
          };
        };

        window-rule = {
          open-maximized = true;
        };

        binds = {
          "Mod+S".spawn-sh = "${lib.getExe self'.packages.myNoctalia} msg panel-toggle launcher";
          "Mod+Return".spawn-sh = lib.getExe pkgs.alacritty;
          "Mod+Q".close-window = {};
          "Mod+Shift+Slash".show-hotkey-overlay = {};
          "Mod+Shift+E".quit = {};

          # Column & Workspace Focus (Vim HJKL)
          "Mod+H".focus-column-left = {};
          "Mod+L".focus-column-right = {};
          "Mod+K".focus-workspace-up = {};
          "Mod+J".focus-workspace-down = {};

          # Move Columns & Workspaces (Vim Ctrl + HJKL)
          "Mod+Ctrl+H".move-column-left = {};
          "Mod+Ctrl+L".move-column-right = {};
          "Mod+Ctrl+K".move-column-to-workspace-up = {};
          "Mod+Ctrl+J".move-column-to-workspace-down = {};

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
