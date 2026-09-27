# Template Hardware Configuration
# Generate with: nixos-generate-config --show-hardware-config > <machine-name>-hardware-configuration.nix
{ self, inputs, ... }:
let
  hostName = baseNameOf ./.;
in
{
  flake.nixosModules."${hostName}Hardware" =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      # Disks, mounts, LUKS UUIDs and swap devices will be declared here by nixos-generate-config
    };
}
