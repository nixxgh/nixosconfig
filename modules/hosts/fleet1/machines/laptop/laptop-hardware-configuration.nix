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

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "uas"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      # Root Filesystem (LUKS encrypted)
      fileSystems."/" = {
        device = "/dev/mapper/luks-1cc0dc7a-4f09-4e78-b6a3-f3517dacfa82";
        fsType = "ext4";
      };

      boot.initrd.luks.devices."luks-1cc0dc7a-4f09-4e78-b6a3-f3517dacfa82".device =
        "/dev/disk/by-uuid/1cc0dc7a-4f09-4e78-b6a3-f3517dacfa82";

      # EFI Boot Partition
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/825A-CB6D";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      # Encrypted Swap & Hibernation Resume
      boot.initrd.luks.devices."luks-68a68627-8cc4-4132-9267-1695eba4cc48".device =
        "/dev/disk/by-uuid/68a68627-8cc4-4132-9267-1695eba4cc48";

      swapDevices = [
        { device = "/dev/mapper/luks-68a68627-8cc4-4132-9267-1695eba4cc48"; }
      ];

      boot.resumeDevice = "/dev/disk/by-uuid/1b011439-393c-4a66-8cc9-3fc39a376733";

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
