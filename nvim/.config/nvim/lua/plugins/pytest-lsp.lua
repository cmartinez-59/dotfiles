return {
  "neovim/nvim-lspconfig",
  opts = {
    -- Register the server so LazyVim's LSP keymaps/UI pick it up.
    -- mason = false because pytest-language-server isn't in Mason's registry;
    -- install it yourself (uv tool install / pipx / brew / cargo).
    servers = {
      pytest_lsp = {
        mason = false,
      },
    },
    -- LazyVim calls opts.setup[server_name] instead of the default setup
    -- when present, which lets us define + enable a server lspconfig
    -- doesn't ship a preset for.
    setup = {
      pytest_lsp = function(_, server_opts)
        local lspconfig = require("lspconfig")
        local configs = require("lspconfig.configs")

        if not configs.pytest_lsp then
          configs.pytest_lsp = {
            default_config = {
              cmd = { "pytest-language-server" },
              filetypes = { "python" },
              root_dir = lspconfig.util.root_pattern("pyproject.toml", "setup.py", "setup.cfg", "pytest.ini", ".git"),
              single_file_support = true,
            },
          }
        end

        lspconfig.pytest_lsp.setup(server_opts)
        return true -- tell LazyVim not to also run the default setup
      end,
    },
  },
}
