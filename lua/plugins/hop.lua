return {
    {
        "phaazon/hop.nvim",
        branch = "v2",
        config = function()
            require("hop").setup {
                multi_windows = true,
            }
        end,
        keys = {
            { mode = "", "<Leader>s", "<Cmd>HopChar2<CR>", desc = "Hop to char2" },
            { mode = "", "<Leader>;", "<Cmd>HopWord<CR>", desc = "Hop to word" },
        },
    },
}
