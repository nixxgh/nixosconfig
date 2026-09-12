{ self, inputs, ... }: {
  flake.nixosModules.ssh = { config, pkgs, lib, ... }: let
    autologinScript = pkgs.writeShellScriptBin "autologin" ''
      set -e

      # Re-execute under sudo if run by an unprivileged user
      if [ "$EUID" -ne 0 ]; then
        exec sudo "$0" "$@"
      fi

      cleanup() {
        rm -f /etc/sddm.conf.d/zz-autologin.conf
      }
      trap cleanup EXIT ERR INT TERM

      NIRI_BIN="${config.programs.niri.package}/bin/niri"

      find_niri_sock() {
        for s in /run/user/1000/niri.*.sock; do
          if [ -S "$s" ] && sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$s" "$NIRI_BIN" msg version >/dev/null 2>&1; then
            echo "$s"
            return 0
          fi
        done
        return 1
      }

      CURRENT_SOCK="$(find_niri_sock || true)"
      ACTION="''${1:-toggle}"

      case "$ACTION" in
        status|--status|-s)
          if [ -n "$CURRENT_SOCK" ]; then
            echo "🟢 Niri session is ACTIVE and unlocked (socket: $CURRENT_SOCK)."
            if systemctl is-active --quiet sunshine; then
              echo "📺 Sunshine desktop streaming service is RUNNING."
            fi
          else
            echo "⚪ No active Niri session found. Machine is waiting at SDDM login screen."
          fi
          exit 0
          ;;

        logout|--logout|-l)
          if [ -n "$CURRENT_SOCK" ]; then
            echo "==> Active Niri session detected. Logging out..."
            cleanup
            sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$CURRENT_SOCK" "$NIRI_BIN" msg action quit --skip-confirmation 2>/dev/null || true
            systemctl restart display-manager
            echo "🔒 Logged out cleanly. SDDM login screen is now active."
          else
            echo "ℹ️ No active Niri session found; system is already at SDDM login screen."
          fi
          exit 0
          ;;

        toggle|login|--login)
          # If already running and toggling, log out back to SDDM
          if [ -n "$CURRENT_SOCK" ] && [ "$ACTION" = "toggle" ]; then
            echo "==> Niri session is currently running. Toggling: Logging out..."
            cleanup
            sudo -u nixx env XDG_RUNTIME_DIR=/run/user/1000 NIRI_SOCKET="$CURRENT_SOCK" "$NIRI_BIN" msg action quit --skip-confirmation 2>/dev/null || true
            systemctl restart display-manager
            echo "🔒 Logged out cleanly. SDDM login screen is now active."
            exit 0
          fi

          if [ -n "$CURRENT_SOCK" ]; then
            echo "🟢 Niri session is already running and unlocked."
            exit 0
          fi

          echo "==> [1/3] Injecting one-shot SDDM autologin configuration..."
          mkdir -p /etc/sddm.conf.d
          cat << 'AUTOCONF' > /etc/sddm.conf.d/zz-autologin.conf
[Autologin]
User=nixx
Session=niri.desktop
Relogin=false
AUTOCONF

          echo "==> [2/3] Restarting display-manager to initialize desktop session..."
          systemctl restart display-manager

          echo "==> [3/3] Waiting for Niri compositor and IPC socket to be ready..."
          READY_SOCK=""
          for i in $(seq 1 40); do
            READY_SOCK="$(find_niri_sock || true)"
            if [ -n "$READY_SOCK" ]; then
              break
            fi
            sleep 0.5
          done

          # Clean up autologin drop-in immediately so future reboots stay at SDDM
          cleanup

          if [ -z "$READY_SOCK" ]; then
            echo "❌ Error: Timed out waiting for responsive Niri socket in /run/user/1000."
            exit 1
          fi

          echo ""
          echo "✅ Success! Niri is active and desktop session is unlocked."
          if systemctl is-active --quiet sunshine; then
            echo "📱 Sunshine is active! You can now open Moonlight on your phone to stream."
          else
            echo "📱 Niri session is ready."
          fi
          echo "💡 Tip: Run 'autologin' again (or 'autologin --logout') anytime from Termius to return to SDDM."
          ;;

        *)
          echo "Usage: autologin [status | logout | login | toggle]"
          echo "  autologin             - Toggle session (logs in if at SDDM, logs out if running)"
          echo "  autologin --status    - Check whether Niri is currently running"
          echo "  autologin --logout    - Explicitly log out back to SDDM"
          echo "  autologin --login     - Explicitly log into Niri"
          exit 1
          ;;
      esac
    '';

    autounlockScript = pkgs.writeShellScriptBin "autounlock" ''
      exec /run/current-system/sw/bin/autologin "$@"
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

    # System packages for remote session control
    environment.systemPackages = [
      autologinScript
      autounlockScript
    ];

    # Allow users in wheel group (e.g. nixx over SSH via Termius) to reboot and power off without password prompts
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.login1.power-off" ||
             action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
             action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
             action.id == "org.freedesktop.login1.reboot" ||
             action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
             action.id == "org.freedesktop.login1.reboot-ignore-inhibit") &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Passwordless sudo for remote administration via SSH (Termius)
    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          { command = "/run/current-system/sw/bin/systemctl reboot"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/systemctl poweroff"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/reboot"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/poweroff"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/shutdown"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/autologin"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/autounlock"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/ethtool"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];
  };
}
