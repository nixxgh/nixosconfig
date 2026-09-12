{ self, inputs, ... }: {
  flake.nixosModules.wakeonlan = { config, pkgs, lib, ... }: {
    # Tool for inspecting and configuring Wake-on-LAN
    environment.systemPackages = with pkgs; [
      ethtool
    ];

    # Declarative systemd .link configuration for eno1
    networking.interfaces.eno1.wakeOnLan.enable = true;

    # NetworkManager global configuration: enforce Magic Packet WoL on all ethernet connections
    networking.networkmanager.connectionConfig = {
      "ethernet.wake-on-lan" = "magic";
    };

    # NetworkManager dispatcher script to re-arm Wake-on-LAN whenever ethernet link is established
    networking.networkmanager.dispatcherScripts = [
      {
        source = pkgs.writeShellScript "wol-ethernet" ''
          IFACE="$1"
          ACTION="$2"
          if [ "$IFACE" = "eno1" ] && [ "$ACTION" = "up" ]; then
            ${pkgs.ethtool}/bin/ethtool -s "$IFACE" wol g 2>/dev/null || true
            if [ -f "/sys/class/net/$IFACE/device/power/wakeup" ]; then
              echo enabled > "/sys/class/net/$IFACE/device/power/wakeup" 2>/dev/null || true
            fi
          fi
        '';
        type = "basic";
      }
    ];

    # Udev rule to configure WoL as soon as the network interface is added by the kernel
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", NAME=="eno1", RUN+="${pkgs.ethtool}/bin/ethtool -s eno1 wol g"
    '';

    # Boot-time oneshot service ensuring Wake-on-LAN is active
    systemd.services.wake-on-lan-eno1 = {
      description = "Enable Wake-on-LAN on eno1";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.ethtool}/bin/ethtool -s eno1 wol g";
        RemainAfterExit = true;
      };
    };
  };
}
