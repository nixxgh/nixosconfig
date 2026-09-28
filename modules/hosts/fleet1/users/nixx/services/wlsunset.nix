{ self, inputs, ... }: {
  flake.homeModules.wlsunset =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.wlsunset = {
        enable = true;
        latitude = "19.07";
        longitude = "72.87";
        temperature = {
          day = 6500;
          night = 4000;
        };
      };
    };
}
