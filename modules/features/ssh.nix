{ self, inputs, ... }: {
  flake.nixosModules.ssh = { config, pkgs, lib, ... }: let
    niriBin = "${config.programs.niri.package}/bin/niri";
    swaylockBin = "${pkgs.swaylock-effects}/bin/swaylock";

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

      echo "==> [3/4] Waiting for Niri compositor and IPC socket to be ready..."
      NIRI_SOCK=""
      for i in $(seq 1 40); do
        for s in /run/user/1000/niri.*.sock; do
          if [ -S "$s" ] && sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$s" ${niriBin} msg version >/dev/null 2>&1; then
            NIRI_SOCK="$s"
            break 2
          fi
        done
        sleep 0.5
      done

      # Clean up autologin immediately so future reboots/logouts stay at SDDM
      rm -f /etc/sddm.conf.d/zz-autologin.conf

      if [ -z "$NIRI_SOCK" ] || [ ! -S "$NIRI_SOCK" ]; then
        echo "❌ Error: Timed out waiting for responsive Niri socket in /run/user/1000"
        exit 1
      fi

      echo "==> [4/4] Engaging lockscreen in active session..."
      sleep 1
      sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action spawn -- \
        ${swaylockBin} -f -e -l -c 1e1e2e --screenshots --clock --indicator --effect-blur 7x5

      echo ""
      echo "✅ Success! Niri is active, screen is locked, and Sunshine is streaming."
      echo "📱 You can now open Moonlight on your phone to connect!"
    '';

    autolockScript = pkgs.writeShellScriptBin "autolock" ''
      NIRI_SOCK=""
      if [ -n "$NIRI_SOCKET" ] && [ -S "$NIRI_SOCKET" ]; then
        NIRI_SOCK="$NIRI_SOCKET"
      else
        for s in /run/user/1000/niri.*.sock; do
          if [ -S "$s" ]; then
            NIRI_SOCK="$s"
            break
          fi
        done
      fi

      if [ -z "$NIRI_SOCK" ]; then
        echo "❌ Error: Active Niri session not found in /run/user/1000"
        exit 1
      fi

      if pgrep -x swaylock >/dev/null; then
        echo "ℹ️ Screen is already locked."
        exit 0
      fi

      if [ "$USER" = "nixx" ]; then
        env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action spawn -- \
          ${swaylockBin} -f -e -l -c 1e1e2e --screenshots --clock --indicator --effect-blur 7x5
      else
        sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action spawn -- \
          ${swaylockBin} -f -e -l -c 1e1e2e --screenshots --clock --indicator --effect-blur 7x5
      fi
      echo "🔒 Lockscreen engaged."
    '';

    screenOffScript = pkgs.writeShellScriptBin "screen-off" ''
      NIRI_SOCK=""
      if [ -n "$NIRI_SOCKET" ] && [ -S "$NIRI_SOCKET" ]; then
        NIRI_SOCK="$NIRI_SOCKET"
      else
        for s in /run/user/1000/niri.*.sock; do
          if [ -S "$s" ]; then
            NIRI_SOCK="$s"
            break
          fi
        done
      fi

      if [ -z "$NIRI_SOCK" ]; then
        echo "❌ Error: Active Niri session not found in /run/user/1000"
        exit 1
      fi

      if [ "$USER" = "nixx" ]; then
        env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action power-off-monitors
      else
        sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action power-off-monitors
      fi
      echo "Monitor powered off (streaming continues)."
    '';

    screenOnScript = pkgs.writeShellScriptBin "screen-on" ''
      NIRI_SOCK=""
      if [ -n "$NIRI_SOCKET" ] && [ -S "$NIRI_SOCKET" ]; then
        NIRI_SOCK="$NIRI_SOCKET"
      else
        for s in /run/user/1000/niri.*.sock; do
          if [ -S "$s" ]; then
            NIRI_SOCK="$s"
            break
          fi
        done
      fi

      if [ -z "$NIRI_SOCK" ]; then
        echo "❌ Error: Active Niri session not found in /run/user/1000"
        exit 1
      fi

      if [ "$USER" = "nixx" ]; then
        env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action power-on-monitors
      else
        sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action power-on-monitors
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

    # Automatically set NIRI_SOCKET and WAYLAND_DISPLAY in interactive shells (e.g. over SSH)
    environment.interactiveShellInit = ''
      if [ -z "$NIRI_SOCKET" ] && [ -d "/run/user/$UID" ]; then
        for s in /run/user/$UID/niri.*.sock; do
          [ -S "$s" ] || continue
          export NIRI_SOCKET="$s"
          wl=$(ls /run/user/$UID/wayland-* 2>/dev/null | grep -v '\.lock$' | head -n 1)
          [ -n "$wl" ] && export WAYLAND_DISPLAY="$(basename "$wl")"
          break
        done
      fi
    '';

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
