{ self, inputs, ... }: {
  flake.nixosModules.ssh = { config, pkgs, lib, ... }: {
    # OpenSSH Server
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
      openFirewall = true;
    };

    # Allow users in wheel group (e.g. nixx over SSH via Termius) to reboot and power off without password prompts
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.login1.power-off" ||
             action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
             action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
             action.id == "org.freedesktop.login1.reboot" ||
             action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
             action.id == "org.freedesktop.login1.reboot-ignore-inhibit") &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Passwordless sudo for reboot and shutdown commands
    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          { command = "/run/current-system/sw/bin/systemctl reboot"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/systemctl poweroff"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/reboot"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/poweroff"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/shutdown"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];
  };
}
