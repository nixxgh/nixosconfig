{ self, inputs, ... }: {
  flake.homeModules.nixx = { config, pkgs, lib, ... }: {
    home.username = "nixx";
    home.homeDirectory = "/home/nixx";
    home.stateVersion = "24.11";

    # Let Home Manager manage itself
    programs.home-manager.enable = true;

    # User packages moved from configuration.nix + dev tools
    home.packages = with pkgs; [
      yt-dlp
      antigravity-cli
      ripgrep
      fd
    ];

    # Git configuration (modern Home Manager syntax)
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "nixxgh";
          email = "275239900+nixxgh@users.noreply.github.com";
        };
        init.defaultBranch = "main";
      };
    };

    # GitHub CLI
    programs.gh = {
      enable = true;
    };

    # Web Browser
    programs.firefox = {
      enable = true;
    };

    # Neovim (Level 2: Batteries included for Nix & development)
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      plugins = with pkgs.vimPlugins; [
        nvim-treesitter.withAllGrammars
        telescope-nvim
        plenary-nvim
        catppuccin-nvim
        lualine-nvim
      ];

      extraLuaConfig = ''
        -- Leader key
        vim.g.mapleader = " "

        -- Core editor options
        vim.opt.clipboard = "unnamedplus"
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.shiftwidth = 2
        vim.opt.tabstop = 2
        vim.opt.expandtab = true
        vim.opt.termguicolors = true
        vim.opt.signcolumn = "yes"
        vim.opt.updatetime = 250
        vim.opt.timeoutlen = 300

        -- Theme & Statusline
        vim.cmd.colorscheme "catppuccin-mocha"
        require('lualine').setup {
          options = {
            theme = 'catppuccin'
          }
        }

        -- Telescope Keymaps
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
      '';
    };
  };
}
