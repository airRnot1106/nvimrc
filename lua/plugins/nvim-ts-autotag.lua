return {
    name = "nvim-ts-autotag",
    repo = "windwp/nvim-ts-autotag",
    on_event = { "BufReadPre", "BufNewFile" },
    lua_source = function()
        require("nvim-ts-autotag").setup {
            opts = {
                enable_close = true, -- Auto close tags
                enable_rename = true, -- Auto rename pairs of tags
                enable_close_on_slash = true, -- Auto close on trailing </
            },
        }
    end,
}
