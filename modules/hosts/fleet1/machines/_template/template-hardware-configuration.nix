# ==============================================================================
# Machine Hardware Configuration Template
# ==============================================================================
# To populate this file for a new physical machine:
# 1. Run: nixos-generate-config --show-hardware-config
# 2. Paste the generated filesystem, kernelModules, and root disk declarations inside
#    the module body below.
#
# ⚠️ THE CALAMARES / ENCRYPTED SWAP GOTCHA:
# If this machine was installed with encrypted swap or hibernation using the NixOS
# GUI installer (Calamares), check your old /etc/nixos/configuration.nix!
# Calamares often dumps the SWAP LUKS mapping and resumeDevice into configuration.nix
# instead of hardware-configuration.nix. Ensure you copy both lines here below.
# ==============================================================================

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

      # ── 1. Kernel Modules & Boot Devices (from nixos-generate-config) ──────
      # boot.initrd.availableKernelModules = [ ... ];
      # boot.initrd.kernelModules = [ ];
      # boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd"
      # boot.extraModulePackages = [ ];

      # ── 2. Filesystems & Root LUKS (from nixos-generate-config) ───────────
      # fileSystems."/" = {
      #   device = "/dev/mapper/luks-<root-uuid>";
      #   fsType = "ext4";
      # };
      # boot.initrd.luks.devices."luks-<root-uuid>".device = "/dev/disk/by-uuid/<root-uuid>";
      # fileSystems."/boot" = {
      #   device = "/dev/disk/by-uuid/<boot-uuid>";
      #   fsType = "vfat";
      # };

      # ── 3. Encrypted Swap & Hibernation (The Calamares Gotcha) ─────────────
      # Check /etc/nixos/configuration.nix for these lines if using encrypted swap:
      # boot.initrd.luks.devices."luks-<swap-uuid>".device = "/dev/disk/by-uuid/<swap-uuid>";
      # swapDevices = [ { device = "/dev/mapper/luks-<swap-uuid>"; } ];
      # boot.resumeDevice = "/dev/disk/by-uuid/<swap-uuid>";
    };
}
