return {
    name = "vim-smartword",
    repo = "kana/vim-smartword",
    on_event = { "BufReadPre", "BufNewFile" },
    lua_source = function()
        vim.keymap.set("n", "w", "<Plug>(smartword-w)", { noremap = false, silent = true })
        vim.keymap.set("n", "b", "<Plug>(smartword-b)", { noremap = false, silent = true })
        vim.keymap.set("n", "e", "<Plug>(smartword-e)", { noremap = false, silent = true })
    end,
}
