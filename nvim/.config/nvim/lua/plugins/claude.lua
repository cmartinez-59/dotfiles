return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = {
    "ClaudeCode",
    "ClaudeCodeFocus",
    "ClaudeCodeAdd",
    "ClaudeCodeSend",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
    "ClaudeCodeCloseAllDiffs",
  },
  opts = {
    -- Terminal split behavior
    terminal = {
      split_side = "right",
      split_width_percentage = 0.35,
      auto_close = true,
    },
    -- Diff review behavior — keep it conservative by default
    diff = {
      auto_close_on_accept = true,
      keep_terminal_focus = false,
    },
  },
  keys = {
    { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },

    -- Session management
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },

    -- Context feeding
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file from tree",
      ft = { "oil", "neo-tree", "NvimTree" },
    },

    -- Diff review — deliberately separate from accidental keys, no auto-accept-all
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    { "<leader>ax", "<cmd>ClaudeCodeCloseAllDiffs<cr>", desc = "Close all pending diffs" },
  },
}
