{ self, inputs, ... }: {
  flake.homeModules.astal =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      themeJson = pkgs.writeText "theme.json" (builtins.toJSON self.theme);
      compiledAstal = pkgs.runCommand "astal-shell-config" {
        nativeBuildInputs = [ pkgs.tailwindcss pkgs.gnused ];
      } ''
        cp -r ${./.} $out
        chmod -R +w $out
        cp ${themeJson} $out/src/theme.json
        cd $out
        tailwindcss -i src/style.css -o src/style.css -c tailwind.config.cjs
        # Ensure trailing semicolons for GTK CSS parser compatibility
        sed -i '/:/ { /[{};,]/! s/$/;/ }' src/style.css
      '';
    in
    {
      imports = [
        inputs.ags.homeManagerModules.default
      ];

      home.packages = [
        pkgs.tailwindcss
        pkgs.adwaita-icon-theme
      ];

      programs.ags = {
        enable = true;
        configDir = compiledAstal;
        systemd.enable = true;
        extraPackages = [
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.astal4
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.battery
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.wireplumber
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.network
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.bluetooth
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.notifd
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.apps
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.mpris
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.tray
          inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.powerprofiles
        ];
      };
    };
}
