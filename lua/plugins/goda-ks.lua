return {
    name = "goda-ks",
    "airRnot1106/goda-ks.vim",
    dependencies = { "goda.vim", "kensaku-search" },
    build = "nix build",
    event = { "CmdlineEnter", "CmdlineChanged" },
    config = function()
        vim.keymap.set("c", "<CR>", "<Plug>(kensaku-search-replace)<CR>", { noremap = true, silent = true })
    end,
}
