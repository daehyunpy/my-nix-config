return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = true,
  version = false,
  opts = {
    provider = "copilot",
    behaviour = {
      auto_focus_sidebar = false,
    },
  },
  build = "make",
  keys = {
    { "<leader>a", "", mode = { "n", "v" }, desc = "+ai" },
  },
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    {
      "zbirenbaum/copilot.lua",
      optional = true,
    },
  },
}
