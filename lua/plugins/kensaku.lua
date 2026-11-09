return {
    name = "kensaku",
    "lambdalisue/kensaku.vim",
    dependencies = { "kensaku-search" },
    event = { "CmdlineEnter", "CmdlineChanged" },
    config = function()
        vim.keymap.set("c", "<CR>", "<Plug>(kensaku-search-replace)<CR>", { noremap = true, silent = true })
    end,
}
