{ self, inputs, ... }: {
  flake.nixosModules.ssh = { config, pkgs, lib, ... }: let
    autounlockScript = pkgs.writeShellScriptBin "autounlock" ''
      set -e
      if [ "$EUID" -ne 0 ]; then
        echo "❌ Please run with sudo: sudo autounlock"
        exit 1
      fi

      echo "==> [1/4] Writing temporary SDDM autologin configuration..."
      mkdir -p /etc/sddm.conf.d
      cat << 'AUTOCONF' > /etc/sddm.conf.d/zz-autologin.conf
[Autologin]
User=nixx
Session=niri.desktop
Relogin=false
AUTOCONF

      echo "==> [2/4] Restarting display-manager to initiate Niri session..."
      systemctl restart display-manager

      echo "==> [3/4] Waiting for Niri compositor to initialize..."
      for i in $(seq 1 30); do
        if [ -S /run/user/1000/wayland-1 ] || [ -S /run/user/1000/wayland-0 ]; then
          break
        fi
        sleep 0.5
      done

      # Clean up autologin immediately so future reboots/logouts stay at SDDM
      rm -f /etc/sddm.conf.d/zz-autologin.conf

      echo "==> [4/4] Engaging lockscreen in active session..."
      sleep 1.5
      sudo -u nixx XDG_RUNTIME_DIR=/run/user/1000 niri msg action spawn -- \
        ${pkgs.swaylock-effects}/bin/swaylock -f -e -l -c 1e1e2e --screenshots --clock --indicator --effect-blur 7x5

      echo ""
      echo "✅ Success! Niri is active, screen is locked, and Sunshine is streaming."
      echo "📱 You can now open Moonlight on your phone to connect!"
    '';

    autolockScript = pkgs.writeShellScriptBin "autolock" ''
      if [ "$USER" = "nixx" ]; then
        niri msg action spawn -- \
          ${pkgs.swaylock-effects}/bin/swaylock -f -e -l -c 1e1e2e --screenshots --clock --indicator --effect-blur 7x5
      else
        sudo -u nixx XDG_RUNTIME_DIR=/run/user/1000 niri msg action spawn -- \
          ${pkgs.swaylock-effects}/bin/swaylock -f -e -l -c 1e1e2e --screenshots --clock --indicator --effect-blur 7x5
      fi
    '';

    screenOffScript = pkgs.writeShellScriptBin "screen-off" ''
      if [ "$USER" = "nixx" ]; then
        niri msg action power-off-monitors
      else
        sudo -u nixx XDG_RUNTIME_DIR=/run/user/1000 niri msg action power-off-monitors
      fi
      echo "Monitor powered off (streaming continues)."
    '';

    screenOnScript = pkgs.writeShellScriptBin "screen-on" ''
      if [ "$USER" = "nixx" ]; then
        niri msg action power-on-monitors
      else
        sudo -u nixx XDG_RUNTIME_DIR=/run/user/1000 niri msg action power-on-monitors
      fi
      echo "Monitor powered on."
    '';
  in {
    # OpenSSH Server
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
      openFirewall = true;
    };

    # PAM configuration for swaylock password validation
    security.pam.services.swaylock = {};

    # System utilities for remote access & session control
    environment.systemPackages = [
      pkgs.swaylock-effects
      autounlockScript
      autolockScript
      screenOffScript
      screenOnScript
    ];
  };
}
