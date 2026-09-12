{ self, inputs, ... }: {
  flake.nixosModules.tailscale = { config, pkgs, lib, ... }: {
    # Tailscale daemon & CLI
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
    };

    # Trust Tailscale virtual interface and allow exit-node routing
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose";
    };
  };
}
