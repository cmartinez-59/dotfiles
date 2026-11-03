-- Python linting: flake8, pylint and mypy, alongside the ruff LSP from the
-- lang.python extra. Together these are the four tools a project like ctetsv
-- configures, so the editor reports what a CLI run reports.
--
-- Two problems are solved for every one of them:
--
--  1. Binary resolution. nvim-lint's builtin specs invoke a bare command from
--     PATH. Without an activated virtualenv that means `pylint` is not found at
--     all, `mypy` silently resolves to a system install blind to the project's
--     site-packages, and `ruff` resolves to mason's copy at a different version.
--     Each cmd below resolves the project's own venv first.
--
--  2. Config discovery. flake8, pylint and mypy all look for their config
--     relative to the *process* cwd, which in nvim is wherever it was launched.
--     Editing a file from $HOME therefore silently applies tool defaults --
--     measurably so: pylint reports 85 messages with the project's .pylintrc and
--     150 without it. Each config is located by walking up from the buffer and
--     passed explicitly.

local VENV_DIRS = { ".venv", "venv", "env" }

-- Config files per tool, closest-first. Entries with a `section` are shared files
-- (pyproject.toml, setup.cfg, tox.ini) that only count when they actually carry
-- settings for that tool -- handing one without the section to --config/--rcfile
-- makes the tool error out or silently apply nothing.
local CONFIGS = {
  flake8 = {
    { file = ".flake8" },
    { file = "setup.cfg", section = "%[flake8%]" },
    { file = "tox.ini", section = "%[flake8%]" },
  },
  pylint = {
    { file = ".pylintrc" },
    { file = "pylintrc" },
    { file = "pyproject.toml", section = "%[tool%.pylint" },
    { file = "setup.cfg", section = "%[pylint%." },
    { file = "tox.ini", section = "%[pylint%." },
  },
  mypy = {
    { file = "mypy.ini" },
    { file = ".mypy.ini" },
    { file = "pyproject.toml", section = "%[tool%.mypy%]" },
    { file = "setup.cfg", section = "%[mypy%]" },
  },
}

--- mypy refuses to check anything when the project's declared target predates the
--- syntax used by stubs in a modern site-packages. With python_version = "3.10"
--- against numpy's 3.12-era stubs, every run dies on
---   numpy/__init__.pyi: error: Type statement is only supported in Python 3.12
--- and reports "errors prevented further checking" -- zero useful diagnostics.
---
--- Raising the floor for the editor is the only workaround that keeps import
--- following, and therefore cross-module errors, which is most of what mypy is
--- worth here (--follow-imports=skip also gets it running, but drops those).
--- The real fix belongs in the project: bump python_version, or build the venv on
--- the version actually targeted.
local MYPY_SYNTAX_FLOOR = 12

--- Directory to resolve project files against: the buffer's own directory, since
--- nvim's cwd may have nothing to do with the file being linted.
local function buf_dir()
  local name = vim.api.nvim_buf_get_name(0)
  return name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
end

local function read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and lines or {}
end

--- Nearest config for `tool` at or above `dir`, or nil if the project has none.
local function find_config(tool, dir)
  for _, candidate in ipairs(CONFIGS[tool]) do
    local found = vim.fs.find(candidate.file, { upward = true, path = dir, type = "file" })[1]
    if found then
      if not candidate.section then
        return found
      end
      for _, line in ipairs(read_lines(found)) do
        if line:match("^%s*" .. candidate.section) then
          return found
        end
      end
    end
  end
  return nil
end

--- Prefer the project's virtualenv, mirroring the pyright pythonPath detection in
--- plugins/python.lua. mason's and the system's copies of these tools drift from
--- the versions a project pins, so resolving here keeps editor diagnostics
--- identical to a CLI run inside the project.
local function venv_bin(name)
  return function()
    local root = vim.fs.root(buf_dir(), vim.list_extend({ ".git" }, VENV_DIRS))
    if root then
      for _, venv in ipairs(VENV_DIRS) do
        local exe = root .. "/" .. venv .. "/bin/" .. name
        if vim.fn.executable(exe) == 1 then
          return exe
        end
      end
    end
    return name
  end
end

--- Only lint projects that opted into a tool. Without a config these fall back to
--- defaults (flake8 at 79 columns, pylint with every convention check on) that
--- would bury every buffer in warnings the project does not care about.
local function when_configured(tool)
  return function(ctx)
    return find_config(tool, ctx.dirname) ~= nil
  end
end

--- `--flag=value` for the located config, or a no-op. Every element of an nvim-lint
--- arg list has to evaluate to a string: returning nil leaves a hole in the list
--- and truncates it. `condition` already guarantees a config was found, so the
--- fallback only matters if that ever changes.
local function config_arg(tool, flag, no_op)
  return function()
    local config = find_config(tool, buf_dir())
    return config and (flag .. "=" .. config) or no_op
  end
end

--- Bump mypy's target only when the project declares one below the floor, so
--- projects with a target mypy can already handle are left alone.
local function mypy_version_arg()
  return function()
    local config = find_config("mypy", buf_dir())
    if config then
      for _, line in ipairs(read_lines(config)) do
        local minor = line:match("^%s*python_version%s*=%s*['\"]?3%.(%d+)")
        if minor and tonumber(minor) < MYPY_SYNTAX_FLOOR then
          return "--python-version=3." .. MYPY_SYNTAX_FLOOR
        end
      end
    end
    return "--no-pretty" -- already passed below; harmless to repeat
  end
end

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint-cli2" },
        -- pylint is deliberately absent: it is the slow one (~1.7s vs 0.2s for
        -- flake8), so it runs on save only, via the autocmd in init below,
        -- rather than on every InsertLeave like LazyVim's default events.
        python = { "flake8", "mypy" },
      },
      linters = {
        ["markdownlint-cli2"] = {
          args = {
            "--config",
            vim.fn.expand("~/.markdownlint-cli2.jsonc"),
            "--",
          },
        },
        -- Each `args` below fully replaces the builtin list: LazyVim merges with
        -- tbl_deep_extend, which overwrites lists by index, so a shorter list
        -- would leave the builtin's tail behind.
        flake8 = {
          condition = when_configured("flake8"),
          cmd = venv_bin("flake8"),
          args = {
            config_arg("flake8", "--config", "--extend-ignore="),
            "--format=%(path)s:%(row)d:%(col)d:%(code)s:%(text)s",
            "--no-show-source",
            "--stdin-display-name",
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
            "-",
          },
        },
        pylint = {
          condition = when_configured("pylint"),
          cmd = venv_bin("pylint"),
          args = {
            config_arg("pylint", "--rcfile", "--score=no"),
            "-f",
            "json",
            "--from-stdin",
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
          },
        },
        mypy = {
          condition = when_configured("mypy"),
          cmd = venv_bin("mypy"),
          args = {
            config_arg("mypy", "--config-file", "--no-pretty"),
            mypy_version_arg(),
            -- Report only the checked file's own errors. mypy otherwise reports
            -- every followed module too (104 errors across 5 files for one buffer
            -- here), and nvim-lint resolves those relative paths against nvim's
            -- cwd -- so from the wrong cwd another file's errors land on this
            -- buffer at meaningless line numbers. `silent` still follows imports,
            -- unlike `skip`, so cross-module signature checking survives.
            "--follow-imports=silent",
            "--show-column-numbers",
            "--show-error-end",
            "--hide-error-context",
            "--no-color-output",
            "--no-error-summary",
            "--no-pretty",
          },
        },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("pylint_on_save", { clear = true }),
        pattern = "*.py",
        callback = function()
          local lint = require("lint")
          local linter = lint.linters.pylint
          local ctx = { filename = vim.api.nvim_buf_get_name(0) }
          ctx.dirname = vim.fs.dirname(ctx.filename)
          if linter and (not linter.condition or linter.condition(ctx)) then
            lint.try_lint("pylint")
          end
        end,
      })
    end,
  },
}
