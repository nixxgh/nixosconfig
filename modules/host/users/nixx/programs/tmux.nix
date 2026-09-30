{ self, inputs, ... }: {
  flake.homeModules.tmux =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
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
          bind \\ split-window -h -c "#{pane_current_path}"
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

          # Set 24-bit true color, italics, and extended keys (CSI u / Kitty protocol)
          set -as terminal-features ",xterm-256color:RGB"
          set -as terminal-features ",alacritty:RGB:extkeys"
          set -s extended-keys on

          # Mouse selection: keep highlight on drag release and sync to clipboard via OSC 52
          set -s set-clipboard on
          bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-no-clear
          bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel

          # Persistent right-click pane menu (-O flag prevents instant dismiss on mouse release)
          bind-key -n MouseDown3Pane display-menu -O -T "#[align=centre]#{pane_index} (#{pane_id})" -t = -x M -y M \
            "Horizontal Split" h "split-window -h -c '#{pane_current_path}'" \
            "Vertical Split"   v "split-window -v -c '#{pane_current_path}'" \
            "" \
            "Swap Up"          u "swap-pane -U" \
            "Swap Down"        d "swap-pane -D" \
            "" \
            "Kill Pane"        x "kill-pane" \
            "Respawn Pane"     R "respawn-pane -k" \
            "#{?window_zoomed_flag,Unzoom,Zoom}" z "resize-pane -Z"

          # Allow image passthrough for terminal tools like Yazi
          set -g allow-passthrough on
          set -ga update-environment TERM
          set -ga update-environment TERM_PROGRAM

          # Clean, minimal status bar
          set -g status-position bottom
          set -g status-style "bg=default,fg=colour7"
          set -g status-left "#[bold,fg=green][#S] "
          set -g status-right "#[fg=cyan]%H:%M #[fg=white]%d-%b"
          set -g window-status-current-format "#[bold,fg=yellow]● #I:#W"
          set -g window-status-format "#[fg=colour8]○ #I:#W"

          # Seamless terminal transparency & background matching
          set -g window-style "bg=default"
          set -g window-active-style "bg=default"
          set -g pane-border-style "fg=#3c3836,bg=default"
          set -g pane-active-border-style "fg=#fe8019,bg=default"
        '';
      };
    };
}
