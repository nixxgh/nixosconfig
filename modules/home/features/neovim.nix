{ self, inputs, ... }: {
  flake.homeModules.neovim = { pkgs, lib, ... }: {
    home.packages = with pkgs; [
      ripgrep
      fd
      nixfmt
    ];

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withRuby = false;
      withPython3 = false;

      plugins = with pkgs.vimPlugins; [
        nvim-treesitter.withAllGrammars
        telescope-nvim
        plenary-nvim
        catppuccin-nvim
        lualine-nvim
        nvim-web-devicons
        vim-tmux-navigator
        conform-nvim
      ];

      initLua = ''
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
            theme = 'catppuccin-mocha'
          }
        }

        -- Telescope Keymaps
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })

        -- Conform (Formatting with nixfmt)
        require('conform').setup({
          formatters_by_ft = {
            nix = { "nixfmt" },
          },
          format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
          },
        })

        -- Format keymap: <leader>cf (Code Format)
        vim.keymap.set({ 'n', 'v' }, '<leader>cf', function()
          require('conform').format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 500,
          })
        end, { desc = 'Format buffer with nixfmt' })
      '';
    };
  };
}
