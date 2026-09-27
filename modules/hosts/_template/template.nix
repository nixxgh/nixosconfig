# ==============================================================================
# Workstation Host Template
# ==============================================================================
# To add a new machine to the fleet:
# 1. Copy this folder:
#      cp -r modules/hosts/_template modules/hosts/fleet1/machines/<machine-name>
# 2. Rename files to match the machine name:
#      mv modules/hosts/fleet1/machines/<machine-name>/template.nix modules/hosts/fleet1/machines/<machine-name>/<machine-name>-configuration.nix
#      mv modules/hosts/fleet1/machines/<machine-name>/template-hardware-configuration.nix modules/hosts/fleet1/machines/<machine-name>/<machine-name>-hardware-configuration.nix
# 3. Populate your hardware scan into <machine-name>-hardware-configuration.nix:
#      nixos-generate-config --show-hardware-config > modules/hosts/fleet1/machines/<machine-name>/<machine-name>-hardware-configuration.nix
# 4. Add to git and rebuild:
#      git add modules/hosts/fleet1/machines/<machine-name>
#      sudo nixos-rebuild switch --flake /home/nixx/myNixOS#<machine-name>
# ==============================================================================

{ self, inputs, ... }:
let
  hostName = baseNameOf ./.;
  baseHostModules = [
    # Shared workstation base profile (Users, Niri, SDDM, audio, fonts, docker, etc.)
    self.nixosModules.commonHost

    # Machine hardware configuration (<directory>-hardware-configuration.nix)
    self.nixosModules."${hostName}Hardware"

    # Machine-specific identity & hardware quirks
    ({ config, pkgs, ... }: {
      networking.hostName = hostName;
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
