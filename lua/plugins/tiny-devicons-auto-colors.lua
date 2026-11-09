return {
    name = "tiny-devicons-auto-colors",
    "rachartier/tiny-devicons-auto-colors.nvim",
    dependencies = { "nvim-web-devicons", "rose-pine" },
    event = { "VimEnter" },
    config = function()
        local theme_colors = require "rose-pine.palette"
        require("tiny-devicons-auto-colors").setup {
            colors = theme_colors,
        }
    end,
}
