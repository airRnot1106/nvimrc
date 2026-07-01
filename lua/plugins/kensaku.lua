return {
    name = "kensaku",
    repo = "lambdalisue/kensaku.vim",
    depends = { "kensaku-search" },
    on_event = { "CmdlineEnter", "CmdlineChanged" },
    lua_source = function()
        vim.keymap.set("c", "<CR>", "<Plug>(kensaku-search-replace)<CR>", { noremap = true, silent = true })
    end,
}
