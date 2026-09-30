{ lib, ... }: {
  options.flake.theme = lib.mkOption {
    type = lib.types.anything;
    default = { };
    description = "Centralized system theme and palette tokens";
  };

  config.flake.theme = rec {
    # Raw hex (without '#')
    raw = {
      bg = "000000";
      surface = "1a1a1a";
      surfaceElevated = "2c2c2c";
      surfaceMuted = "0f172a";
      surfaceBorder = "1e293b";
      border = "5a5a5a";
      borderInactive = "242424";
      text = "f8fafc";
      textMuted = "94a3b8";
      accent = "10b981";       # Emerald 500
      accentLight = "34d399";  # Emerald 400
      accentTeal = "5eead4";   # Teal 300
      danger = "ef4444";       # Red 500
    };

    # Hex with '#'
    hex = lib.mapAttrs (_: v: "#" + v) raw;

    # Formatted RGB strings
    rgb = {
      bg = "rgb(0, 0, 0)";
      surface = "rgb(26, 26, 26)";
      surfaceElevated = "rgb(44, 44, 44)";
      surfaceMuted = "rgb(15, 23, 42)";
      surfaceBorder = "rgb(30, 41, 59)";
      border = "rgb(90, 90, 90)";
      borderInactive = "rgb(36, 36, 36)";
      text = "rgb(248, 250, 252)";
      textMuted = "rgb(148, 163, 184)";
      accent = "rgb(16, 185, 129)";
      accentLight = "rgb(52, 211, 153)";
      accentTeal = "rgb(94, 234, 212)";
      danger = "rgb(239, 68, 68)";
    };
  };
}
