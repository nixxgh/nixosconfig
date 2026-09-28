{ self, inputs, ... }: {
  flake.nixosModules.security =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Enable PAM authentication for hyprlock screen locker
      security.pam.services.hyprlock = { };
    };
}
