# ==============================================================================
# User Profile Template
# ==============================================================================
# To add a new user to this system or adopt on another machine:
# 1. Copy this folder:
#      cp -r modules/hosts/fleet1/users/_template modules/hosts/fleet1/users/<username>
# 2. Rename configuration:
#      mv modules/hosts/fleet1/users/<username>/template-configuration.nix modules/hosts/fleet1/users/<username>/<username>-configuration.nix
# 3. Adjust personal git credentials in modules/hosts/fleet1/users/<username>/programs/git.nix
# 4. In modules/hosts/fleet1/fleet-configuration/fleet-configuration.nix, add user account and assign:
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
        # Core development & terminal programs
        self.homeModules.git
        self.homeModules.neovim
        self.homeModules.firefox
        self.homeModules.zsh
        self.homeModules.tmux
        self.homeModules.yazi
        self.homeModules.fastfetch
        self.homeModules.zen
        self.homeModules.alacritty
        self.homeModules.direnv
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
