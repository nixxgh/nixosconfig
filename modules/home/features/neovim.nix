{ self, inputs, ... }: {
  flake.homeModules.neovim = { pkgs, lib, ... }: {
    home.packages = with pkgs; [
      ripgrep
      fd
    ];

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
