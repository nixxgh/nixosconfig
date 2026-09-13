{ self, inputs, ... }: {
  flake.homeModules.neovim = { pkgs, lib, ... }: {
    home.packages = with pkgs; [
      ripgrep
      fd
      nixfmt
      nixd
      prettier
      astro-language-server
      typescript-language-server
      tailwindcss-language-server
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
        harpoon2
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

        -- Tree-sitter Highlighting & Indentation
        require('nvim-treesitter.configs').setup({
          highlight = {
            enable = true,
          },
          indent = {
            enable = true,
          },
        })

        -- Telescope Keymaps
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })

        -- Harpoon (Fast file pinning & speed dial)
        local harpoon = require('harpoon')
        harpoon:setup()

        vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end, { desc = 'Harpoon add file' })
        vim.keymap.set('n', '<leader>h', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })
        vim.keymap.set('n', '<C-e>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })
        vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'Harpoon file 1' })
        vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'Harpoon file 2' })
        vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'Harpoon file 3' })
        vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'Harpoon file 4' })

        -- Conform (Formatting with nixfmt & prettier)
        require('conform').setup({
          formatters_by_ft = {
            nix = { "nixfmt" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            javascriptreact = { "prettier" },
            typescriptreact = { "prettier" },
            astro = { "prettier" },
            css = { "prettier" },
            html = { "prettier" },
            json = { "prettier" },
            jsonc = { "prettier" },
            markdown = { "prettier" },
          },
          format_on_save = {
            timeout_ms = 1000,
            lsp_fallback = true,
          },
        })

        -- Format keymap: <leader>cf (Code Format)
        vim.keymap.set({ 'n', 'v' }, '<leader>cf', function()
          require('conform').format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 1000,
          })
        end, { desc = 'Format buffer with nixfmt/prettier' })

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

        -- Web Language Servers (Astro, TypeScript, Tailwind CSS)
        lspconfig.astro.setup({})
        lspconfig.ts_ls.setup({})
        lspconfig.tailwindcss.setup({})
      '';
    };
  };
}
