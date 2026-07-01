return {
    name = "skkeleton_indicator",
    repo = "delphinus/skkeleton_indicator.nvim",
    lazy = true,
    lua_source = function()
        require("skkeleton_indicator").setup {
            border = "rounded",
            eijiHlName = "LineNr",
            hiraHlName = "String",
            kataHlName = "Todo",
            hankataHlName = "Special",
            zenkakuHlName = "LineNr",
        }
    end,
}
