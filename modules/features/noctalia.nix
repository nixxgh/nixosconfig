{ self , inputs, ... }: {

  perSystem = { pkgs, ... }: {

    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      # override the default package with the new v5 beta flake
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = 
        (builtins.fromJSON
          (builtins.readFile ./.noctalia.json)).settings;
      
    };

  };

}
