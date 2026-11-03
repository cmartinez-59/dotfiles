return {
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "pyright",
        "debugpy",
        "markdownlint-cli2",
        "markdown-toc",
      },
    },
  },
}
