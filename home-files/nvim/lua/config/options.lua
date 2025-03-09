-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.python3_host_prog = "python"

if os.getenv("TMUX") or "" ~= "" then
  vim.g.clipboard = {
    name = "tmux",
    copy = {
      ["+"] = "tmux load-buffer -w -",
      ["*"] = "tmux load-buffer -w -",
    },
    paste = {
      ["+"] = "tmux save-buffer -",
      ["*"] = "tmux save-buffer -",
    },
    cache_enabled = 1,
  }
end

vim.opt.clipboard = "unnamedplus"
vim.opt.colorcolumn = "72,79"
