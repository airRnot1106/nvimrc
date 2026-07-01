return {
    name = "tiny-devicons-auto-colors",
    repo = "rachartier/tiny-devicons-auto-colors.nvim",
    depends = { "nvim-web-devicons", "rose-pine" },
    on_event = { "VimEnter" },
    lua_source = function()
        local theme_colors = require "rose-pine.palette"
        require("tiny-devicons-auto-colors").setup {
            colors = theme_colors,
        }
    end,
}
