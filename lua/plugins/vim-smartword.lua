return {
    name = "vim-smartword",
    "kana/vim-smartword",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        vim.keymap.set("n", "w", "<Plug>(smartword-w)", { noremap = false, silent = true })
        vim.keymap.set("n", "b", "<Plug>(smartword-b)", { noremap = false, silent = true })
        vim.keymap.set("n", "e", "<Plug>(smartword-e)", { noremap = false, silent = true })
    end,
}
