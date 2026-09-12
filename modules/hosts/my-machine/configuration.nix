{ self, inputs, ... }: {

  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      # Hardware & System Features
      self.nixosModules.myMachineHardware
      self.nixosModules.niri
      self.nixosModules.sddm
      self.nixosModules.audio
      self.nixosModules.bluetooth
      self.nixosModules.noctalia
      self.nixosModules.tailscale
      self.nixosModules.sunshine
      self.nixosModules.ssh
      self.nixosModules.homeManager

      # Machine Base Configuration (Chassis)
      ({ config, pkgs, ... }: {
        # Environment Aliases
        environment.shellAliases = {
          rebuild = "(cd /home/nixx/myNixOS && git add . && (git diff --cached --quiet || (git commit -m 'no comment by user' && (git push || echo '⚠️ git push failed, continuing locally...')))) && sudo nixos-rebuild switch --flake /home/nixx/myNixOS#myMachine";
          ncupdate = "nix run nixpkgs#noctalia -- config export > ~/myNixOS/modules/features/.noctalia-config.toml " +
                     "&& echo 'stage and commit myNixOS, to keep tree clean!'";
          nixclean = "nix-collect-garbage -d && sudo nix-collect-garbage -d && nix store optimise";
          ff = "fastfetch";
        };

        # Bootloader
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        # Disk Encryption (LUKS)
        boot.initrd.luks.devices."luks-68a68627-8cc4-4132-9267-1695eba4cc48".device = "/dev/disk/by-uuid/68a68627-8cc4-4132-9267-1695eba4cc48";

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
          extraGroups = [ "networkmanager" "wheel" "docker" ];
          packages = with pkgs; [];
        };

        # System Packages & Unfree License
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = with pkgs; [];

        # Fonts
        fonts = {
          packages = with pkgs; [
            nerd-fonts.jetbrains-mono
          ];
          fontconfig = {
            enable = true;
            defaultFonts = {
              monospace = [ "JetBrainsMono Nerd Font" "DejaVu Sans Mono" ];
            };
          };
        };

        # Root Daemons
        virtualisation.docker.enable = true;

        # Nix Settings & Maintenance
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nix.settings.auto-optimise-store = true;
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
