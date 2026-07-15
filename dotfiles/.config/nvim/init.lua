require("config.lazy")

--------------------------------------------------
-- clipboard (headless / SSH → host via OSC 52)
--------------------------------------------------
-- No X/Wayland display here, so the usual clipboard tools can't reach the
-- host. Over SSH, route the system clipboard through OSC 52, which Neovim
-- ships a provider for. `yy` etc. then land in the host clipboard.
vim.o.clipboard = "unnamedplus"
if os.getenv("SSH_TTY") ~= nil then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
  }
end

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local dir = vim.fn.expand("<afile>:p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

--------------------------------------------------
-- number and relative number
--------------------------------------------------
local NumberToggle = vim.api.nvim_create_augroup("NumberToggle", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "BufReadPost", "BufNewFile" }, {
  group = NumberToggle,
  pattern = "*",
  callback = function()
    vim.wo.number = true
    vim.wo.relativenumber = true
  end,
})
vim.api.nvim_create_autocmd("InsertEnter", {
  group = NumberToggle,
  pattern = "*",
  callback = function()
    vim.wo.relativenumber = false
    vim.wo.number = true
  end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
  group = NumberToggle,
  pattern = "*",
  callback = function()
    vim.wo.relativenumber = true
  end,
})

--------------------------------------------------
-- vim-commentary
--------------------------------------------------
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.envrc.local", "*.envrc" },
  command = "setfiletype sh",
})

--------------------------------------------------
-- conform formatter
--------------------------------------------------
-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = "*",
--   callback = function(args)
--     require("conform").format({ bufnr = args.buf, verbose = true })
--   end,
-- })
vim.keymap.set("n", "<leader>f", function()
  -- `bufnr = vim.api.nvim_get_current_buf()` is the same value you passed in the autocmd
  require("conform").format({ bufnr = vim.api.nvim_get_current_buf() })
end, { desc = "Format buffer with Prettier" })

--------------------------------------------------
-- lsp LLM inline completion
--------------------------------------------------
vim.lsp.enable("copilot")
vim.lsp.inline_completion.enable(true)

vim.keymap.set("i", "<C-CR>", function()
  if not vim.lsp.inline_completion.get() then
    return "<C-CR>"
  end
end, {
  expr = true,
  replace_keycodes = true,
  desc = "Get the current inline completion",
})
