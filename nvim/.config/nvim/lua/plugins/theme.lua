return {
  {
    --"ellisonleao/gruvbox.nvim",
    "Mofiqul/adwaita.nvim",
    lazy = false,
    priority = 1000,

    opts = {
      contrast = "hard",
      terminal_colors = true,
    },

    config = function()
      vim.cmd("colorscheme adwaita")
    end,
  },
}
