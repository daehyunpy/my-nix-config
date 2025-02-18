return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = true,
  version = false,
  opts = {
    provider = "copilot",
    copilot = {
      model = "o3-mini",
      temperature = 0,
      max_tokens = 64000,
      reasoning_effort = "high",
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
