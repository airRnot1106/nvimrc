return {
    name = "mini.splitjoin",
    repo = "nvim-mini/mini.splitjoin",
    on_map = { nv = { "gS" } },
    lua_source = function()
        require("mini.splitjoin").setup()
    end,
}
