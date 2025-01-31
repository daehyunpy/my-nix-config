return {
  {
    "Vigemus/iron.nvim",
    opts = function()
      require("iron.core").setup({
        repl_definition = {
          python = {
            command = { "ipython", "--no-autoindent" },
            format = require("iron.fts.common").bracketed_paste_python,
            block_deviders = { "# %%" },
          },
        },
        scratch_repl = true,
        ignore_blank_lines = true,
        repl_open_cmd = require("iron.view").bottom(20),
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
          exit = "<leader>Rsq",
          clear = "<leader>Rcl",
        },
      })
    end,
  },
}
