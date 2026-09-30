# ==============================================================================
# Workstation Machine Profile Template
# ==============================================================================
# To add a new machine to this fleet:
# 1. Copy this folder:
#      cp -r modules/hosts/fleet1/machines/_template modules/hosts/fleet1/machines/<machine-name>
# 2. Rename files to match the machine name:
#      mv modules/hosts/fleet1/machines/<machine-name>/template-configuration.nix modules/hosts/fleet1/machines/<machine-name>/<machine-name>-configuration.nix
#      mv modules/hosts/fleet1/machines/<machine-name>/template-hardware-configuration.nix modules/hosts/fleet1/machines/<machine-name>/<machine-name>-hardware-configuration.nix
# 3. Populate your hardware scan into <machine-name>-hardware-configuration.nix:
#      nixos-generate-config --show-hardware-config > modules/hosts/fleet1/machines/<machine-name>/<machine-name>-hardware-configuration.nix
# 4. Add to git and rebuild:
#      git add modules/hosts/fleet1/machines/<machine-name>
#      sudo nixos-rebuild switch --flake .#<machine-name>
# ==============================================================================

{ self, inputs, ... }:
let
  hostName = baseNameOf ./.;
  baseHostModules = [
    # Shared workstation base profile (Users, Niri, SDDM, audio, fonts, docker, etc.)
    self.nixosModules.commonHost

    # Machine hardware configuration (<directory>-hardware-configuration.nix)
    self.nixosModules."${hostName}Hardware"

    # ── Machine-Specific Identity & Hardware Quirks (Chassis Override Layer) ──
    # Customize settings specific ONLY to this physical device here without
    # polluting the shared fleet configuration:
    ({ config, pkgs, ... }: {
      networking.hostName = hostName;

      # Example Laptop Chassis Tweaks:
      # services.libinput.touchpad.tapping = true;
      # services.logind.settings.Login.HandleLidSwitch = "lock";

      # Example Dedicated GPU / Workstation Tweaks:
      # services.xserver.videoDrivers = [ "nvidia" ];
      # hardware.graphics.enable = true;
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
