{ self, inputs, ... }: {
  flake.nixosModules.sunshine = { config, pkgs, lib, ... }: {
    # Sunshine Game/Desktop Streaming Host
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;     # Required for DRM/KMS Wayland capture
      openFirewall = true;    # Opens Sunshine streaming & web UI ports
    };

    # Moonlight Qt client for connecting to other hosts
    environment.systemPackages = with pkgs; [
      moonlight-qt
    ];

    # Enable input group for virtual gamepad/mouse emulation
    users.users.nixx.extraGroups = [ "input" ];
  };
}
