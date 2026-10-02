{ self, inputs, ... }: {
  flake.nixosModules.tailscale =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Tailscale daemon & CLI
      services.tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = "client";
      };

      # Trust Tailscale and Hotspot wireless interfaces, allow exit-node routing
      networking.firewall = {
        trustedInterfaces = [ "tailscale0" "wlo1" ];
        checkReversePath = "loose";
      };
    };
}
