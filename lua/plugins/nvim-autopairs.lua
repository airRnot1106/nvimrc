return {
    name = "nvim-autopairs",
    repo = "windwp/nvim-autopairs",
    on_event = { "BufReadPre", "BufNewFile" },
    lua_source = function()
        -- let ddc handle <CR> so completion confirm and snippet expansion work
        require("nvim-autopairs").setup { map_cr = false }
    end,
}
