return {
    name = "fidget",
    repo = "j-hui/fidget.nvim",
    lua_source = function()
        require("fidget").setup()
    end,
}
