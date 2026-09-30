{ self, inputs, ... }: {

  flake.nixosModules.commonHost =
    { config, pkgs, lib, ... }:
    {
      imports = [
        # System programs & services
        self.nixosModules.niri
        self.nixosModules.sddm
        self.nixosModules.audio
        self.nixosModules.bluetooth
        self.nixosModules.tailscale
        self.nixosModules.sunshine
        self.nixosModules.ssh
        self.nixosModules.wakeonlan
        self.nixosModules.homeManager
        self.nixosModules.environmentPackages
        self.nixosModules.fleetUsers
        self.nixosModules.security
        self.nixosModules.stylix
      ];

      # ========================================================================
      # Shell Aliases
      # ========================================================================
      environment.shellAliases = {
        # ── 1. Core Architecture Rebuild Pipelines (The Framework) ───────────
        # Full system rebuild (cascading, rebuilds environment + all user spaces)
        forcerebuildall = "(cd \$HOME/myNixOS && git add . && (git diff --cached --quiet || git commit -m 'no comment by user') && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && (git push || echo '⚠️ git push failed, continuing locally...')) && sudo nixos-rebuild switch --flake \$HOME/myNixOS#${config.networking.hostName}";

        forceupdateall = "(cd \$HOME/myNixOS && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && nix flake update && git add flake.lock && (git diff --cached --quiet || (git commit -m 'Update flake.lock' && (git push || echo '⚠️ git push failed, continuing locally...'))) && nix build .#nixosConfigurations.${config.networking.hostName}.config.system.build.toplevel --no-link) && forcerebuildall";

        # Environment rebuild (non-cascading, leaves home-manager untouched)
        rebuildenvironment = "(cd \$HOME/myNixOS && git add . && (git diff --cached --quiet || git commit -m 'no comment by user') && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && (git push || echo '⚠️ git push failed, continuing locally...')) && sudo nixos-rebuild switch --flake \$HOME/myNixOS#${config.networking.hostName}-env";

        updateenvironment = "(cd \$HOME/myNixOS && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && nix flake update && git add flake.lock && (git diff --cached --quiet || (git commit -m 'Update flake.lock' && (git push || echo '⚠️ git push failed, continuing locally...'))) && nix build .#nixosConfigurations.${config.networking.hostName}-env.config.system.build.toplevel --no-link) && rebuildenvironment";

        # Store & Garbage Collection
        cleanenvironment = "sudo nix-collect-garbage -d && nix store optimise";
        forcecleanall = "(nix-env --delete-generations old -p ~/.local/state/nix/profiles/home-manager 2>/dev/null || true) && nix-collect-garbage -d && sudo nix-collect-garbage -d && nix store optimise";
      };

      # Bootloader & Display Emulation
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Force unused HDMI-A-1 as a virtual 1920x1440 display for wireless iPad streaming
      boot.kernelParams = [
        "video=HDMI-A-1:1920x1440@60e"
      ];

      # Networking
      networking.networkmanager.enable = true;

      # Time Zone & Localization
      time.timeZone = "Asia/Kolkata";
      i18n.defaultLocale = "en_IN";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_IN";
        LC_IDENTIFICATION = "en_IN";
        LC_MEASUREMENT = "en_IN";
        LC_MONETARY = "en_IN";
        LC_NAME = "en_IN";
        LC_NUMERIC = "en_IN";
        LC_PAPER = "en_IN";
        LC_TELEPHONE = "en_IN";
        LC_TIME = "en_IN";
      };

      # Ensure user session environments explicitly retain UTF-8 for compose tables
      environment.sessionVariables = {
        LANG = lib.mkForce "en_IN.UTF-8";
        LC_ALL = lib.mkForce "en_IN.UTF-8";
      };

      # Keyboard
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # Default Shell Support
      programs.zsh.enable = true;

      # ========================================================================
      # User Accounts & Access Control:
      # Delegated to ./users.nix (centralized permission & onboarding directory)
      # ========================================================================

      # Allow Unfree Packages
      nixpkgs.config.allowUnfree = true;

      # Fonts
      fonts = {
        packages = with pkgs; [
          nerd-fonts.jetbrains-mono
        ];
        fontconfig = {
          enable = true;
          defaultFonts = {
            monospace = [
              "JetBrainsMono Nerd Font"
              "DejaVu Sans Mono"
            ];
          };
        };
      };

      # Root Daemons
      virtualisation.docker.enable = true;

      # Nix Settings & Maintenance
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nix.settings.auto-optimise-store = true;
      nix.settings.trusted-users = [ "root" "@wheel" ];
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };

      system.stateVersion = "26.05";
    };
}
