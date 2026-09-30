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

      stylix.targets.zen-browser.profileNames = [ "default" ];

      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
        profiles.default = {
          id = 0;
          name = "Default Profile";
          isDefault = true;
          path = "rzitq07l.Default Profile";
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/plain" = lib.mkForce "nvim.desktop";
        };
      };
    };
}
