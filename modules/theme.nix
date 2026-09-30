{ lib, ... }: {
  options.flake.theme = lib.mkOption {
    type = lib.types.anything;
    default = { };
    description = "Centralized system theme and palette tokens";
  };

  config.flake.theme = rec {
    # Raw hex (without '#') - Gruvbox Dark Hard
    raw = {
      bg = "1d2021";              # base00 hard background
      surface = "282828";         # dark0
      surfaceElevated = "3c3836"; # base01
      surfaceMuted = "1d2021";    # base00
      surfaceBorder = "504945";   # base02
      border = "665c54";          # base03
      borderInactive = "3c3836";  # base01
      text = "ebdbb2";            # base06 light1
      textMuted = "a89984";       # gray
      accent = "fe8019";          # base09 orange / bright
      accentLight = "fabd2f";     # base0A yellow
      accentTeal = "8ec07c";      # base0C aqua
      danger = "fb4934";          # base08 red
    };

    # Hex with '#'
    hex = lib.mapAttrs (_: v: "#" + v) raw;

    # Formatted RGB strings
    rgb = {
      bg = "rgb(29, 32, 33)";
      surface = "rgb(40, 40, 40)";
      surfaceElevated = "rgb(60, 56, 54)";
      surfaceMuted = "rgb(29, 32, 33)";
      surfaceBorder = "rgb(80, 73, 69)";
      border = "rgb(102, 92, 84)";
      borderInactive = "rgb(60, 56, 54)";
      text = "rgb(235, 219, 178)";
      textMuted = "rgb(168, 153, 132)";
      accent = "rgb(254, 128, 25)";
      accentLight = "rgb(250, 189, 47)";
      accentTeal = "rgb(142, 192, 124)";
      danger = "rgb(251, 73, 52)";
    };
  };
}
