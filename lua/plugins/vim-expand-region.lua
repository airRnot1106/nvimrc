return {
    {
        "terryma/vim-expand-region",
        event = "VeryLazy",
        keys = {
            { "'", mode = { "x" }, "<Plug>(expand_region_expand)", desc = "expand_region_expand" },
            { '"', mode = { "x" }, "<Plug>(expand_region_shrink)", desc = "expand_region_shrink" },
        },
    },
}
