{ self, inputs, ... }: {
  flake.nixosModules.ssh = { config, pkgs, lib, ... }: let
    niriBin = "${config.programs.niri.package}/bin/niri";
    gtklockBin = "${pkgs.gtklock}/bin/gtklock";
    swaylockBin = "${pkgs.swaylock-effects}/bin/swaylock";

    autounlockScript = pkgs.writeShellScriptBin "autounlock" ''
      set -e
      if [ "$EUID" -ne 0 ]; then
        echo "❌ Please run with sudo: sudo autounlock"
        exit 1
      fi

      trap 'rm -f /etc/sddm.conf.d/zz-autologin.conf' EXIT INT TERM

      # Check if Niri session is already running
      NIRI_SOCK=""
      for s in /run/user/1000/niri.*.sock; do
        if [ -S "$s" ] && sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$s" ${niriBin} msg version >/dev/null 2>&1; then
          NIRI_SOCK="$s"
          break
        fi
      done

      # If Niri is not running, log in past SDDM to launch the desktop session & Sunshine
      if [ -z "$NIRI_SOCK" ]; then
        echo "==> [1/3] Bypassing SDDM to launch desktop session..."
        mkdir -p /etc/sddm.conf.d
        cat << 'AUTOCONF' > /etc/sddm.conf.d/zz-autologin.conf
[Autologin]
User=nixx
Session=niri.desktop
Relogin=false
AUTOCONF

        systemctl restart display-manager

        echo "==> [2/3] Waiting for Niri and Sunshine to initialize..."
        for i in $(seq 1 40); do
          for s in /run/user/1000/niri.*.sock; do
            if [ -S "$s" ] && sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$s" ${niriBin} msg version >/dev/null 2>&1; then
              NIRI_SOCK="$s"
              break 2
            fi
          done
          sleep 0.5
        done

        rm -f /etc/sddm.conf.d/zz-autologin.conf

        if [ -z "$NIRI_SOCK" ] || [ ! -S "$NIRI_SOCK" ]; then
          echo "❌ Error: Timed out waiting for responsive Niri socket in /run/user/1000"
          exit 1
        fi
        sleep 1
      fi

      # Immediately lock back up with the login screen
      echo "==> [3/3] Engaging login screen..."
      if ! pgrep -x gtklock >/dev/null 2>&1; then
        sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action spawn -- ${gtklockBin} -d
      fi

      echo ""
      echo "✅ Success! Sunshine is streaming, and the screen is locked with the login prompt."
      echo "📱 You can now connect via Moonlight and enter your password to unlock."
    '';

    autologoutScript = pkgs.writeShellScriptBin "autologout" ''
      set -e
      if [ "$EUID" -ne 0 ]; then
        echo "❌ Please run with sudo: sudo autologout"
        exit 1
      fi

      rm -f /etc/sddm.conf.d/zz-autologin.conf

      for s in /run/user/1000/niri.*.sock; do
        if [ -S "$s" ]; then
          sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$s" ${niriBin} msg action quit --skip-confirmation 2>/dev/null || true
          break
        fi
      done

      for i in $(seq 1 25); do
        if ! pgrep -u nixx -x niri >/dev/null 2>&1; then
          break
        fi
        sleep 0.2
      done

      if pgrep -u nixx -x niri >/dev/null 2>&1; then
        sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 systemctl --user stop niri.service 2>/dev/null || true
        sleep 0.5
      fi

      systemctl restart display-manager
      echo "🔒 Logged out. SDDM login screen is now active."
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

      if pgrep -x gtklock >/dev/null; then
        echo "ℹ️ Screen is already locked."
        exit 0
      fi

      if [ "$USER" = "nixx" ]; then
        env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action spawn -- ${gtklockBin} -d
      else
        sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$NIRI_SOCK" ${niriBin} msg action spawn -- ${gtklockBin} -d
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

    # PAM configuration for lockscreen password validation
    security.pam.services.gtklock = {};
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
      pkgs.gtklock
      pkgs.swaylock-effects
      autounlockScript
      autologoutScript
      autolockScript
      screenOffScript
      screenOnScript
    ];
  };
}
