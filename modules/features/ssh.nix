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
  };
}
