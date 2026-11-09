return {
    name = "mini.splitjoin",
    "nvim-mini/mini.splitjoin",
    keys = { { "gS", mode = { "n", "v" } } },
    config = function()
        require("mini.splitjoin").setup()
    end,
}
