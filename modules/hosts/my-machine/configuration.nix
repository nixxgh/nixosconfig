{ self, inputs, ... }: {

  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      # Hardware & System Features
      self.nixosModules.myMachineHardware
      self.nixosModules.niri
      self.nixosModules.sddm
      self.nixosModules.audio
      self.nixosModules.bluetooth
      self.nixosModules.tailscale
      self.nixosModules.sunshine
      self.nixosModules.ssh
      self.nixosModules.wakeonlan
      self.nixosModules.homeManager

      # Machine Base Configuration (Chassis)
      ({ config, pkgs, ... }: {
        # Environment Aliases
        environment.shellAliases = {
          rebuild = "(cd /home/nixx/myNixOS && git add . && (git diff --cached --quiet || (git commit -m 'no comment by user' && (git push || echo '⚠️ git push failed, continuing locally...')))) && sudo nixos-rebuild switch --flake /home/nixx/myNixOS#myMachine";
          update = "(cd /home/nixx/myNixOS && nix flake update && git add flake.lock && (git diff --cached --quiet || (git commit -m 'Update flake.lock' && (git push || echo '⚠️ git push failed, continuing locally...'))) && nix build .#nixosConfigurations.myMachine.config.system.build.toplevel --no-link) && rebuild";
          nixclean = "nix-collect-garbage -d && sudo nix-collect-garbage -d && nix store optimise";
          ff = "fastfetch";

          # JARVIS AI Assistant
          jarvis = "/home/nixx/projects/jarvis/jarvis-voice";
          "jarvis-text" = "/home/nixx/projects/jarvis/jarvis-text";
          j = "/home/nixx/projects/jarvis/jarvis-text";
        };

        # Bootloader
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        # Disk Encryption (LUKS)
        boot.initrd.luks.devices."luks-68a68627-8cc4-4132-9267-1695eba4cc48".device =
          "/dev/disk/by-uuid/68a68627-8cc4-4132-9267-1695eba4cc48";

        # Hibernation / Resume from Swap
        boot.resumeDevice = "/dev/disk/by-uuid/1b011439-393c-4a66-8cc9-3fc39a376733";

        # Power Management (Lock on Lid Close)
        services.logind.settings.Login = {
          HandleLidSwitch = "lock";
          HandleLidSwitchExternalPower = "lock";
        };

        # Networking
        networking.hostName = "nixos";
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

        # Keyboard & Touchpad
        services.xserver.xkb = {
          layout = "us";
          variant = "";
        };
        services.libinput = {
          enable = true;
          touchpad = {
            tapping = true;
          };
        };

        # User Account & Default Shell
        programs.zsh.enable = true;
        users.users."nixx" = {
          isNormalUser = true;
          description = "nixx";
          shell = pkgs.zsh;
          extraGroups = [
            "networkmanager"
            "wheel"
            "docker"
          ];
          packages = with pkgs; [ ];
        };

        # System Packages & Unfree License
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = with pkgs; [ ];

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
        nix.settings.trusted-users = [ "root" "nixx" ];
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };

        system.stateVersion = "26.05";
      })
    ];
  };

}
