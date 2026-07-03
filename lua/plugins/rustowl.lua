return {
    name = "rustowl",
    repo = "cordx56/rustowl",
    on_ft = { "rust" },
    lua_source = function()
        require("rustowl").setup()
    end,
}
