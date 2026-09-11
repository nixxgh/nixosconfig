{ self, inputs, ... }: {
  flake.nixosModules.homeManager = { config, pkgs, lib, ... }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      extraSpecialArgs = { inherit inputs self; };
      users.nixx = self.homeModules.nixx;
    };
  };
}
