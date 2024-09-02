return {
    {
        "rose-pine/neovim",
        name = "rose-pine",
        cond = true,
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd [[colorscheme rose-pine-moon]]
        end,
    },
    {
        "rachartier/tiny-devicons-auto-colors.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        event = "VeryLazy",
        config = function()
            local theme_colors = require "rose-pine.palette"
            require("tiny-devicons-auto-colors").setup {
                colors = theme_colors,
            }
        end,
    },
}
