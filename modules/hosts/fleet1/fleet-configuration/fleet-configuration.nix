{ self, inputs, ... }: {

  flake.nixosModules.commonHost =
    { config, pkgs, ... }:
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
      ];

      # Common Environment Aliases
      environment.shellAliases = {
        nixclean = "nix-collect-garbage -d && sudo nix-collect-garbage -d && nix store optimise";
        ff = "fastfetch";

        # Environment rebuild (non-cascading, leaves home-manager untouched)
        rebuildenvironment = "(cd /home/nixx/myNixOS && git add . && (git diff --cached --quiet || git commit -m 'no comment by user') && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && (git push || echo '⚠️ git push failed, continuing locally...')) && sudo nixos-rebuild switch --flake /home/nixx/myNixOS#\${config.networking.hostName}-env";

        updateenvironment = "(cd /home/nixx/myNixOS && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && nix flake update && git add flake.lock && (git diff --cached --quiet || (git commit -m 'Update flake.lock' && (git push || echo '⚠️ git push failed, continuing locally...'))) && nix build .#nixosConfigurations.\${config.networking.hostName}-env.config.system.build.toplevel --no-link) && rebuildenvironment";

        # Full system rebuild (cascading, rebuilds environment + all user spaces)
        forcerebuildall = "(cd /home/nixx/myNixOS && git add . && (git diff --cached --quiet || git commit -m 'no comment by user') && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && (git push || echo '⚠️ git push failed, continuing locally...')) && sudo nixos-rebuild switch --flake /home/nixx/myNixOS#\${config.networking.hostName}";

        forceupdateall = "(cd /home/nixx/myNixOS && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && nix flake update && git add flake.lock && (git diff --cached --quiet || (git commit -m 'Update flake.lock' && (git push || echo '⚠️ git push failed, continuing locally...'))) && nix build .#nixosConfigurations.\${config.networking.hostName}.config.system.build.toplevel --no-link) && forcerebuildall";
      };

      # Bootloader
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

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

      # Keyboard
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # Default Shell Support
      programs.zsh.enable = true;

      # User Accounts & Privilege Management
      users.users.nixx = {
        isNormalUser = true;
        description = "nixx";
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"          # Administrator / sudo access
          "networkmanager" # Network configuration
          "docker"         # Docker daemon access
          "input"          # Direct hardware input
          "uinput"         # Virtual controller / input emulation
        ];
        packages = with pkgs; [ ];
      };

      # Attach Home Manager profiles
      home-manager.users.nixx = self.homeModules.nixx;

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
