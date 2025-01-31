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
          repl_open_cmd = require("iron.view").bottom(20),
        },
        ignore_blank_lines = true,
        keymaps = {
          toggle_repl = "<leader>Rrr",
          restart_repl = "<leader>RrR",
          send_motion = "<leader>Rsc",
          visual_send = "<leader>Rsc",
          send_file = "<leader>Rsf",
          send_line = "<leader>Rsl",
          send_paragraph = "<leader>Rsp",
          send_until_cursor = "<leader>Rsu",
          send_mark = "<leader>Rsm",
          send_code_block = "<leader>Rsb",
          send_code_block_and_move = "<leader>Rsn",
          mark_motion = "<leader>Rmc",
          mark_visual = "<leader>Rmc",
          remove_mark = "<leader>Rmd",
          cr = "<leader>Rs<cr>",
          interrupt = "<leader>Rs<space>",
          exit = "<leader>Rsq",
          clear = "<leader>Rcl",
        },
      })
      vim.keymap.set("n", "<leader>Rrf", "<cmd>IronFocus<cr>")
      vim.keymap.set("n", "<leader>Rrh", "<cmd>IronHide<cr>")
    end,
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
