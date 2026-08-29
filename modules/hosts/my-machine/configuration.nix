{ self, inputs, ... }: {

  flake.nixosModules.myMachineConfiguration = { config, pkgs, ... }: {
    imports = [ # Include the results of the hardware scan.
      self.nixosModules.myMachineHardware
      self.nixosModules.niri
    ];
    
    # Environment Aliases
    environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake /home/nixx/myNixOS#myMachine";
    ncupdate = "nix run nixpkgs#noctalia -- config export > ~/myNixOS/modules/features/.noctalia-config.toml && echo 'stage and commit myNixOS, to keep tree clean!'";
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.initrd.luks.devices."luks-68a68627-8cc4-4132-9267-1695eba4cc48".device = "/dev/disk/by-uuid/68a68627-8cc4-4132-9267-1695eba4cc48";
    networking.hostName = "nixos"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networking.networkmanager.enable = true;

    # Set your time zone.
    time.timeZone = "Asia/Kolkata";

    # Select internationalisation properties.
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

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users."nixx" = {
      isNormalUser = true;
      description = "nixx";
      extraGroups = [ "networkmanager" "wheel" "docker" ];
      packages = with pkgs; [];
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
      git
      gh
      #temp
      yt-dlp
    ];

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    #temp
    programs.firefox.enable = true;
    virtualisation.docker.enable = true;
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      configure = {
        customRC = ''
          set clipboard+=unnamedplus
        '';
      };
   };
    # List services that you want to enable:

    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;
    
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "26.05"; # Did you read the comment?

  };

}
