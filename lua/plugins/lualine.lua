return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
    event = { "BufNewFile", "BufRead" },
    options = { theme = "gruvbox-material" },
    config = function()
        local lualine = require "lualine"

        -- Config
        local config = {
            sections = {
                lualine_a = { "g:coc_git_blame", "g:coc_status", "bo:filetype" },
                lualine_b = { "g:coc_git_status", "branch", "diff", { "diagnostics", sources = { "coc" } } },
            },
            options = {
                --- @usage 'rose-pine' | 'rose-pine-alt'
                theme = "rose-pine",
            },
        }

        lualine.setup(config)
    end,
}
