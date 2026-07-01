return {
    name = "mini.cursorword",
    repo = "nvim-mini/mini.cursorword",
    on_event = { "BufReadPre", "BufNewFile" },
    lua_source = function()
        require("mini.cursorword").setup()
    end,
}
