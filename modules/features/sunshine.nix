{ self, inputs, ... }: {
  flake.nixosModules.sunshine = { config, pkgs, lib, ... }: {
    # Sunshine Game/Desktop Streaming Host
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;     # Required for DRM/KMS Wayland capture
      openFirewall = true;    # Opens Sunshine streaming & web UI ports
    };

    # Enable input and uinput groups for virtual gamepad/mouse emulation
    users.users.nixx.extraGroups = [ "input" "uinput" ];

    # Automatically grant active graphical session access to /dev/uinput via logind
    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="uinput", MODE="0660", OPTIONS+="static_node=uinput", TAG+="uaccess"
    '';
  };
}
