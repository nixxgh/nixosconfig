{ self, inputs, ... }: {
  flake.homeModules.antigravity =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      antigravityApp = pkgs.antigravity-ide.override {
        commandLineArgs = "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations";
      };
    in
    {
      home.packages = [
        antigravityApp
      ];

      # Quick terminal launchers
      programs.zsh.shellAliases = {
        agui = "antigravity-ide";
        agy-gui = "antigravity-ide";
      };
    };
}
