{ self, inputs, ... }: {
  flake.homeModules.yazi = { config, pkgs, lib, ... }: {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";

      settings = {
        manager = {
          show_hidden = true;
          sort_by = "alphabetical";
          sort_dir_first = true;
          linemode = "size";
        };
      };

      extraPackages = with pkgs; [
        file              # MIME-type detection
        ffmpegthumbnailer # Video previews
        unar              # Archive previews
        jq                # JSON preview
        poppler-utils     # PDF preview
        fd                # Fast file discovery
        ripgrep           # Content searching
        fzf               # Interactive filtering
        zoxide            # Smart directory jumping
        chafa             # Terminal image rendering fallback
      ];
    };
  };
}
