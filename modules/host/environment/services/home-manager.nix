{ self, inputs, ... }: {
  flake.nixosModules.homeManager =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = false;
        backupFileExtension = "backup";
        extraSpecialArgs = { inherit inputs self; };
      };
    };
}
