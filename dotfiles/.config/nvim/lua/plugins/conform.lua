return {
  {
    "stevearc/conform.nvim",
    opts = { -- will be merged with default options
      formatters_by_ft = {
        json = { "prettier_json" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        lua = { "stylua" },
        rust = { "rustfmt" },
        -- add more filetypes as needed
      },
      formatters = {
        prettier = {
          command = "prettier",
          prepend_args = { "--tab-width", "4", "--use-tabs", "false" },
        },
        prettier_json = {
          command = "prettier",
          args = { "--parser", "json", "--tab-width", "4", "--use-tabs", "false" },
        },
      },
      log_level = vim.log.levels.DEBUG,
    },
    event = "BufReadPre",
    config = function(_, opts)
      require("conform").setup(opts)
    end,
    init = function()
      vim.filetype.add({
        extension = {
          vkey = "json",
	  skey = "json",
        },
      })
    end,
  },
}
