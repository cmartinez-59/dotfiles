-- Python LSP with per-project virtualenv detection.
--
-- Mechanism note: LazyVim on nvim 0.11 configures servers through
-- vim.lsp.config()/vim.lsp.enable() -- the native path, which never calls
-- lspconfig's `on_new_config` hook. A venv resolver written there silently never
-- runs (verified: the ruff client still spawned bare `ruff` from PATH, i.e.
-- mason's copy at a different version than the project pins).
--
-- So resolution happens one level down instead: the project's venv/bin is
-- prepended to nvim's PATH before any language server starts. That is what every
-- server's bare `cmd` resolves against, and what pyright uses to find an
-- interpreter -- so it fixes ruff and pyright together, and any future server too.
-- nvim-lint still resolves its binaries explicitly (see plugins/lint.lua), which
-- keeps linting correct even if a buffer is opened before this runs.

local VENV_DIRS = { ".venv", "venv", "env" }
local ROOT_MARKERS = { ".venv", "venv", "env", "pyproject.toml", "setup.py", "setup.cfg", ".git" }

--- Path to the project virtualenv containing `start`, or nil.
local function find_venv(start)
  local root = vim.fs.root(start, ROOT_MARKERS)
  if not root then
    return nil
  end
  for _, dir in ipairs(VENV_DIRS) do
    local venv = root .. "/" .. dir
    if vim.fn.executable(venv .. "/bin/python") == 1 then
      return venv
    end
  end
  return nil
end

-- Guarded so repeated FileType events don't stack duplicate PATH entries. First
-- venv seen wins, which is the right call for one nvim per project; opening a
-- second project in the same session keeps the first project's tools.
local activated = {}

local function activate_venv(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local venv = find_venv(name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd())
  if not venv or activated[venv] then
    return
  end
  activated[venv] = true
  vim.env.PATH = venv .. "/bin:" .. vim.env.PATH
  vim.env.VIRTUAL_ENV = venv
end

return {
  {
    "neovim/nvim-lspconfig",
    -- `init` runs at startup, before the LSP autocmds LazyVim registers, so the
    -- PATH is already correct by the time a server is spawned for the buffer.
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("python_venv_path", { clear = true }),
        pattern = "python",
        callback = function(args)
          activate_venv(args.buf)
        end,
      })
      -- LazyVim's format-on-save (conform.nvim, gated by vim.g.autoformat) is a
      -- global default; vim.b.autoformat overrides it per buffer without touching
      -- formatting for any other filetype (Lua via stylua stays on).
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("python_no_autoformat", { clear = true }),
        pattern = "python",
        callback = function()
          vim.b.autoformat = false
        end,
      })
    end,
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
            },
          },
        },
      })
      return opts
    end,
  },
}
