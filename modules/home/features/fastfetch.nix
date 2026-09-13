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
            padding = {
              top = 1;
              right = 2;
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
