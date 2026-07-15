return {
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "lua_ls", "rust_analyzer" },
    },
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
  },
  -- {
  --   "WhoIsSethDaniel/mason-tool-installer.nvim",
  --   config = function()
  --     require("mason-tool-installer").setup({
  --       ensure_installed = {
  --         "stylua",
  --       },
  --       auto_update = false,
  --       run_on_start = true,
  --     })
  --   end,
  --   dependencies = { "mason-org/mason.nvim" },
  -- },
}
