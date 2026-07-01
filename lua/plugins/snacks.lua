return {
    name = "snacks",
    repo = "folke/snacks.nvim",
    on_event = { "VimEnter" },
    lua_source = function()
        local snacks = require "snacks"
        snacks.setup {
            input = { enabled = true },
            picker = { enabled = true },
        }
        vim.ui.input = snacks.input.input
        vim.ui.select = snacks.picker.select
    end,
}
