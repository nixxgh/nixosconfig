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
        self.homeModules.git
        self.homeModules.neovim
        self.homeModules.firefox
        self.homeModules.zsh
        self.homeModules.tmux
        self.homeModules.yazi
        self.homeModules.zen
        self.homeModules.alacritty
        self.homeModules.direnv
        self.homeModules.packages
        self.homeModules.hypridle
        self.homeModules.hyprlock
        self.homeModules.wlsunset
        self.homeModules.fuzzel
        self.homeModules.nmApplet
      ];

      home.username = userName;
      home.homeDirectory = "/home/${userName}";
      home.stateVersion = "24.11";

      # Let Home Manager manage itself
      programs.home-manager.enable = true;
      news.display = "silent";

      # User-space rebuild & update workflow (zero sudo / root permissions required)
      home.shellAliases = {
        rebuildhome = "(cd ~/myNixOS && git add . && (git diff --cached --quiet || git commit -m 'no comment by user') && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && (git push || echo '⚠️ git push failed, continuing locally...')) && home-manager switch --flake ~/myNixOS#${userName}";
        updatehome = "(cd ~/myNixOS && (git pull --rebase || echo '⚠️ git pull failed/offline, continuing locally...') && nix flake update && git add flake.lock && (git diff --cached --quiet || (git commit -m 'Update flake.lock' && (git push || echo '⚠️ git push failed, continuing locally...')))) && rebuildhome";
        cleanhome = "(nix-env --delete-generations old -p ~/.local/state/nix/profiles/home-manager 2>/dev/null || true) && nix-collect-garbage -d";
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
