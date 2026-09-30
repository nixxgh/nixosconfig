{ self, inputs, ... }: {
  flake.nixosModules.environmentPackages =
    { pkgs, ... }:
    {
      # System-wide packages that do not require dedicated module configuration
      environment.systemPackages = with pkgs; [
        tree
      ];
    };
}
