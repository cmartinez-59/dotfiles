return {
  "tpope/vim-fugitive",
  cmd = { "Git", "Gvdiffsplit", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse" },
  keys = {
    { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
    { "<leader>gc", "<cmd>Git commit<cr>", desc = "Git commit" },
    { "<leader>gp", "<cmd>Git push<cr>", desc = "Git push" },
    { "<leader>gP", "<cmd>Git pull<cr>", desc = "Git pull" },
    { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
    { "<leader>gd", "<cmd>Gvdiffsplit<cr>", desc = "Git diff (vertical)" },
    { "<leader>gl", "<cmd>Git log<cr>", desc = "Git log" },
  },
  config = function()
    -- Auto-close fugitive status buffer with 'q'
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "fugitive",
      callback = function()
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, silent = true })
      end,
    })
  end,
}
