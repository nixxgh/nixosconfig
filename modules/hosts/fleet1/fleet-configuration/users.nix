{ self, inputs, ... }: {

  flake.nixosModules.fleetUsers =
    { config, pkgs, lib, ... }:
    {
      # ========================================================================
      # 🛡️ 1. FLEET ACCESS CONTROL & PERMISSIONS DIRECTORY
      # ========================================================================
      # All user provisioning and privilege delegation across the fleet is
      # centralized in this file. Individual user capsules cannot elevate themselves.
      #
      # Privilege Definitions:
      # • "wheel"          ──► Full sudo root access & trusted Nix daemon operator.
      # • "networkmanager" ──► Configure network interfaces, WiFi, and VPNs.
      # • "docker"         ──► Access Docker daemon socket without root.
      # • "input"          ──► Direct access to physical input devices.
      # • "uinput"         ──► Virtual controller / input emulation (Sunshine, etc.).
      #
      # Role Archetypes:
      # • Administrator: extraGroups = [ "wheel" "networkmanager" "docker" "input" "uinput" ];
      # • Standard Dev:  extraGroups = [ "networkmanager" ]; (ZERO sudo access)
      # ========================================================================

      # ========================================================================
      # 📋 2. ONBOARDING TEMPLATE (COPY-PASTE BELOW TO REGISTER A NEW USER)
      # ========================================================================
      # users.users.<username> = {
      #   isNormalUser = true;
      #   description = "<username>";
      #   shell = pkgs.zsh;
      #   extraGroups = [
      #     # "wheel"          # Uncomment ONLY for fleet administrators
      #     "networkmanager"   # Standard network access
      #   ];
      # };
      # home-manager.users.<username> = self.homeModules.<username>;
      # ========================================================================

      # ========================================================================
      # 👥 3. REGISTERED FLEET USERS
      # ========================================================================

      # ── Fleet Administrators (Full Sudo / Machine Management) ───────────────
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

      home-manager.users.nixx = self.homeModules.nixx;

      # ── Standard Developers (Restricted / Sandboxed to $HOME) ────────────────
      # (Add standard team members here without "wheel" for zero sudo access)
    };
}
