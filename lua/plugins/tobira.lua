return {
    name = "tobira",
    repo = "kamegoro/tobira.nvim",
    on_event = { "BufReadPre", "BufNewFile" },
    lua_source = function()
        require("tobira").setup {
            lang = "ja",
        }
    end,
}
