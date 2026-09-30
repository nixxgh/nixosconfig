{ self, inputs, ... }: {
  flake.homeModules.zen =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.zen-browser.homeModules.default
      ];

      stylix.targets.zen-browser.profileNames = [ "Default Profile" ];

      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/plain" = lib.mkForce "nvim.desktop";
        };
      };
    };
}
