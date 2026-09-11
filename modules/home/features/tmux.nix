{ self, inputs, ... }: {
  flake.homeModules.tmux = { config, pkgs, lib, ... }: {
    programs.tmux = {
      enable = true;
      prefix = "C-a";
      baseIndex = 1;
      escapeTime = 0;
      historyLimit = 10000;
      keyMode = "vi";
      mouse = true;
      terminal = "tmux-256color";

      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
      ];

      extraConfig = ''
        # Allow sending C-a to inner shell by pressing C-a twice
        bind C-a send-prefix

        # Open new windows and splits in the current working directory
        bind c new-window -c "#{pane_current_path}"
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        unbind '"'
        unbind %

        # Easy reload of config
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "Tmux config reloaded!"

        # Quick pane switching with Alt + arrow keys without prefix
        bind -n M-Left select-pane -L
        bind -n M-Right select-pane -R
        bind -n M-Up select-pane -U
        bind -n M-Down select-pane -D

        # Set 24-bit true color and italics support
        set -as terminal-features ",xterm-256color:RGB"
        set -as terminal-features ",alacritty:RGB"

        # Clean, minimal status bar
        set -g status-position bottom
        set -g status-style "bg=default,fg=colour7"
        set -g status-left "#[bold,fg=green][#S] "
        set -g status-right "#[fg=cyan]%H:%M #[fg=white]%d-%b"
        set -g window-status-current-format "#[bold,fg=yellow]● #I:#W"
        set -g window-status-format "#[fg=colour8]○ #I:#W"
      '';
    };
  };
}
