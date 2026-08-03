-- Python LSP with per-project virtual environment detection
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.pyright = {
        on_new_config = function(config, root_dir)
          for _, venv in ipairs({ ".venv", "venv", "env" }) do
            local python = root_dir .. "/" .. venv .. "/bin/python"
            if vim.fn.executable(python) == 1 then
              config.settings.python.pythonPath = python
              return
            end
          end
          config.settings.python.pythonPath = vim.fn.exepath("python3") or "python"
        end,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
              venv = ".venv",
            },
          },
        },
      }
      return opts
    end,
  },
}
