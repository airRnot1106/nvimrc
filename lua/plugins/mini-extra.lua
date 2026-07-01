return {
    name = "mini.extra",
    repo = "nvim-mini/mini.extra",
    lazy = true,
    lua_source = function()
        require("mini.extra").setup()
    end,
}
