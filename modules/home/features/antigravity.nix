{ self, inputs, ... }: {
  flake.homeModules.antigravity =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [
        pkgs.antigravity-ide
      ];

      # Quick terminal launchers
      programs.zsh.shellAliases = {
        agui = "antigravity-ide";
        agy-gui = "antigravity-ide";
      };
    };
}
