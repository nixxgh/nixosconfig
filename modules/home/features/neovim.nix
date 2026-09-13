{ self, inputs, ... }: {
  flake.homeModules.neovim = { pkgs, lib, ... }: {
    home.packages = with pkgs; [
      ripgrep
      fd
      nixfmt
      nixd
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
        nvim-lspconfig
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

        -- Format keymap: <leader>f (Space + f)
        vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
          require('conform').format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 500,
          })
        end, { desc = 'Format buffer with nixfmt' })

        -- LSP Configuration & Keymaps
        local lspconfig = require('lspconfig')

        vim.diagnostic.config({
          virtual_text = true,
          signs = true,
          underline = true,
          update_in_insert = false,
          severity_sort = true,
        })

        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(event)
            local opts = { buffer = event.buf }
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'LSP Hover Docs' }))
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'Go to definition' }))
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = 'Go to references' }))
            vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename symbol' }))
            vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code action' }))
            vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = 'Line diagnostics' }))
            vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, vim.tbl_extend('force', opts, { desc = 'Previous diagnostic' }))
            vim.keymap.set('n', ']d', vim.diagnostic.goto_next, vim.tbl_extend('force', opts, { desc = 'Next diagnostic' }))
          end,
        })

        -- Nix Language Server (nixd)
        lspconfig.nixd.setup({
          settings = {
            nixd = {
              formatting = {
                command = { "nixfmt" },
              },
            },
          },
        })
      '';
    };
  };
}
