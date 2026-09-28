{ self, inputs, ... }: {
  flake.nixosModules.bluetooth =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      hardware.bluetooth = {
        enable = true;
        settings = {
          General = {
            Experimental = true;
            Enable = "Source,Sink,Media,Socket";
          };
        };
      };

      services.blueman.enable = true;
    };
}
