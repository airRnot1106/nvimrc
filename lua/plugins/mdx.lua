return {
    {
        "davidmh/mdx.nvim",
        event = { "BufEnter *.mdx" },
        config = true,
        dependencies = { "nvim-treesitter/nvim-treesitter" },
    },
}
