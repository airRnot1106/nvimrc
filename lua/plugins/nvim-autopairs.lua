return {
    name = "nvim-autopairs",
    "windwp/nvim-autopairs",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        -- let goda-cmp handle <CR> so completion confirm and snippet expansion work
        require("nvim-autopairs").setup { map_cr = false }
    end,
}
