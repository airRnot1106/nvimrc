return {
    {
        "kat0h/bufpreview.vim",
        dependencies = { "vim-denops/denops.vim" },
        build = "deno task prepare",
        lazy = false,
    },
}
