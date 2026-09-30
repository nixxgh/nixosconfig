{ self, inputs, ... }: {
  flake.homeModules.zsh =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        history = {
          size = 10000;
          save = 10000;
          path = "${config.xdg.dataHome}/zsh/history";
          ignoreDups = true;
          share = true;
        };

        initContent = ''
          # Ensure Shift+Enter behaves as regular Enter in shell prompt
          bindkey '^[[13;2u' accept-line

          # Responsive fastfetch: dynamically adjusts logo size and layout based on terminal width
          fastfetch() {
            local cols=$(tput cols 2>/dev/null || echo ''${COLUMNS:-80})
            if (( cols >= 90 )); then
              command fastfetch --logo-type builtin "$@"
            elif (( cols >= 55 )); then
              command fastfetch --logo-type small "$@"
            else
              command fastfetch --logo-type small --logo-position top "$@"
            fi
          }
        '';
      };

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          add_newline = false;
          format = "$directory$git_branch$git_status$character";
          character = {
            success_symbol = "[❯](bold green)";
            error_symbol = "[❯](bold red)";
          };
          directory = {
            style = "bold cyan";
            truncate_to_repo = true;
          };
          git_branch = {
            style = "bold purple";
            symbol = " ";
          };
          git_status = {
            style = "bold red";
          };
        };
      };
    };
}
