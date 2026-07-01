return {
    name = "lazydev.nvim",
    repo = "folke/lazydev.nvim",
    on_ft = { "lua" },
    lua_source = function()
        require("lazydev").setup()
    end,
}
