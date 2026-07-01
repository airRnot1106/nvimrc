return {
    name = "mini.trailspace",
    repo = "nvim-mini/mini.trailspace",
    on_event = { "BufReadPre", "BufNewFile" },
    lua_source = function()
        require("mini.trailspace").setup()
    end,
}
