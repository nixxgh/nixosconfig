{ self, inputs, ... }: {
  flake.homeModules.fastfetch =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.fastfetch = {
        enable = true;
        settings = {
          logo = {
            type = "small";
            padding = {
              top = 1;
              right = 3;
            };
          };
          display = {
            separator = " ➜ ";
            color = {
              keys = "cyan";
              title = "magenta";
            };
          };
          modules = [
            "title"
            "separator"
            {
              type = "os";
              key = "OS";
            }
            {
              type = "host";
              key = "Host";
            }
            {
              type = "kernel";
              key = "Kernel";
            }
            {
              type = "uptime";
              key = "Uptime";
            }
            {
              type = "packages";
              key = "Packages";
              format = "{all} (nix)";
            }
            {
              type = "wm";
              key = "WM";
            }
            {
              type = "terminal";
              key = "Terminal";
            }
            {
              type = "cpu";
              key = "CPU";
            }
            {
              type = "gpu";
              key = "GPU";
              format = "{name}";
            }
            {
              type = "memory";
              key = "Memory";
            }
            {
              type = "disk";
              key = "Disk";
            }
            {
              type = "battery";
              key = "Battery";
            }
            "break"
            "colors"
          ];
        };
      };
    };
}
