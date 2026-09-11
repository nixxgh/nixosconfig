{ self, inputs, ... }: {

  flake.nixosModules.noctalia = { pkgs, lib, ... }: {
    systemd.user.services.noctalia-export-on-shutdown = {
      description = "Export Noctalia settings to flake repository before logout/shutdown";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.writeShellScript "noctalia-export" ''
          ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.myNoctalia} config export > /home/nixx/myNixOS/modules/features/.noctalia-config.toml 2>/dev/null || true
        ''}";
      };
    };
  };

  perSystem = { pkgs, ... }: {

    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      # override the default package with the new v5 beta flake
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = builtins.fromTOML (builtins.readFile ./.noctalia-config.toml);
      
    };

  };

}
