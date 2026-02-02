return {
    {
        "lambdalisue/nvim-aibo",
        config = function()
            require("aibo").setup()
            vim.keymap.set(
                "n",
                "<Leader>aq",
                '<Cmd>Aibo -opener="botright vsplit" claude<CR>',
                { noremap = true, silent = true }
            )
            vim.keymap.set(
                "n",
                "<Leader>ac",
                '<Cmd>Aibo -opener="botright vsplit" claude -c<CR>',
                { noremap = true, silent = true }
            )
            vim.keymap.set(
                "n",
                "<Leader>ar",
                '<Cmd>Aibo -opener="botright vsplit" claude -r<CR>',
                { noremap = true, silent = true }
            )
            vim.keymap.set("n", "<Leader>ad", "<Cmd>bdelete!<CR>", { noremap = true, silent = true })
        end,
    },
}
