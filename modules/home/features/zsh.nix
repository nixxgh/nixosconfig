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

          # Antigravity CLI wrapper with voice mode support
          function agy() {
            if [[ "$1" == "voice" ]]; then
              shift
              touch /tmp/agy_voice_mode
              echo "🎙️  Antigravity Voice Mode Active (TTS enabled on each prompt)"
              command agy "$@"
              rm -f /tmp/agy_voice_mode
            else
              rm -f /tmp/agy_voice_mode
              command agy "$@"
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
