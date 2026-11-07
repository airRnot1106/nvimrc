return {
    name = "mini.cursorword",
    "nvim-mini/mini.cursorword",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("mini.cursorword").setup()
    end,
}
