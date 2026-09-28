# ==============================================================================
# User Profile Template
# ==============================================================================
# To add a new user to this fleet:
# 1. Copy this folder:
#      cp -r modules/hosts/fleet1/users/_template modules/hosts/fleet1/users/<username>
# 2. Rename configuration:
#      mv modules/hosts/fleet1/users/<username>/template-configuration.nix modules/hosts/fleet1/users/<username>/<username>-configuration.nix
# 3. Adjust personal git credentials in:
#      modules/hosts/fleet1/users/<username>/programs/git.nix
# 4. In modules/hosts/fleet1/fleet-configuration/users.nix:
#      Copy the onboarding template in Section 2, paste in Section 3, and set extraGroups:
#      users.users.<username> = { isNormalUser = true; description = "<username>"; shell = pkgs.zsh; extraGroups = [ "networkmanager" ]; };
#      home-manager.users.<username> = self.homeModules.<username>;
# ==============================================================================

{ self, inputs, ... }:
let
  userName = baseNameOf ./.;
in
{
  flake.homeModules.${userName} =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        # Base Git configuration
        self.homeModules.git
        self.homeModules.packages

        # Modular programs (add custom dotfile modules under programs/ and attach here):
        # self.homeModules.zsh
        # self.homeModules.alacritty
        # self.homeModules.neovim
      ];

      home.username = userName;
      home.homeDirectory = "/home/${userName}";
      home.stateVersion = "24.11";

      # Let Home Manager manage itself
      programs.home-manager.enable = true;

      # User-space rebuild & update workflow (zero sudo / root permissions required)
      home.shellAliases = {
        rebuildhome = "(cd ~/myNixOS && git add . && (git diff --cached --quiet || git commit -m 'no comment by user') && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && (git push || echo '⚠️ git push failed, continuing locally...')) && home-manager switch --flake ~/myNixOS#${userName}";
        updatehome = "(cd ~/myNixOS && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && nix flake update && git add flake.lock && (git diff --cached --quiet || (git commit -m 'Update flake.lock' && (git push || echo '⚠️ git push failed, continuing locally...')))) && rebuildhome";
      };
    };

  # Standalone Home Manager configuration: enables running `home-manager switch --flake .#<user>` without root/sudo
  flake.homeConfigurations.${userName} = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit inputs self; };
    modules = [
      { nixpkgs.config.allowUnfree = true; }
      self.homeModules.${userName}
    ];
  };
}
