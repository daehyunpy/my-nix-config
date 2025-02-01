return {
  {
    "Vigemus/iron.nvim",
    event = "VeryLazy",
    opts = function()
      require("iron.core").setup({
        config = {
          repl_definition = {
            sh = {
              command = "zsh",
              block_deviders = { "# %%" },
            },
            python = {
              command = { "ipython", "--no-autoindent" },
              format = require("iron.fts.common").bracketed_paste_python,
              block_deviders = { "# %%" },
            },
          },
          scratch_repl = true,
          repl_open_cmd = "bot split",
        },
        ignore_blank_lines = true,
        keymaps = {
          toggle_repl = "<leader>Rr",
          restart_repl = "<leader>RR",
          send_motion = "<leader>Rc",
          visual_send = "<leader>Rc",
          send_file = "<leader>Ra",
          send_line = "<leader>Rl",
          send_paragraph = "<leader>Rp",
          send_until_cursor = "<leader>Ru",
          send_mark = "<leader>Rm",
          send_code_block = "<leader>Rb",
          send_code_block_and_move = "<leader>Rn",
          mark_motion = "<leader>Ry",
          mark_visual = "<leader>Ry",
          remove_mark = "<leader>Rd",
          cr = "<leader>R<cr>",
          interrupt = "<leader>R<space>",
          exit = "<leader>Rq",
          clear = "<leader>Rk",
        },
      })
    end,
    keys = {
      { "<leader>R", "", mode = { "n", "v" }, desc = "+repl" },
      { "<leader>Rf", "<cmd>IronFocus<cr>" },
      { "<leader>Rh", "<cmd>IronHide<cr>" },
    },
  },
  {
    {
      "benlubas/molten-nvim",
      version = "^1.9.2",
      event = "VeryLazy",
      build = ":UpdateRemotePlugins",
      init = function()
        vim.g.molten_output_win_max_height = 20
      end,
    },
  },
}
