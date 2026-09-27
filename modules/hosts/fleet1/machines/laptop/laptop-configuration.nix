{ self, inputs, ... }:
let
  hostName = baseNameOf ./.;
  baseHostModules = [
    # Shared workstation base profile
    self.nixosModules.commonHost

    # Machine hardware mapping (<directory>-hardware-configuration.nix)
    self.nixosModules."${hostName}Hardware"

    # Laptop-specific identity & hardware quirks
    ({ config, pkgs, ... }: {
      networking.hostName = hostName;

      # Touchpad tapping (laptop chassis)
      services.libinput.touchpad.tapping = true;

      # Power management: lock on lid close
      services.logind.settings.Login = {
        HandleLidSwitch = "lock";
        HandleLidSwitchExternalPower = "lock";
      };
    })
  ];
in
{
  # Full system configuration (cascades to all Home Manager users)
  flake.nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
    modules = baseHostModules;
  };

  # Environment-only configuration (non-cascading, skips Home Manager)
  flake.nixosConfigurations."${hostName}-env" = inputs.nixpkgs.lib.nixosSystem {
    modules = baseHostModules ++ [
      ({ lib, ... }: {
        home-manager.users = lib.mkForce { };
      })
    ];
  };
}
