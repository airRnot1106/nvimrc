return {
    {
        "bkad/CamelCaseMotion",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local keymap = vim.api.nvim_set_keymap
            keymap("o", "iw", "<Plug>CamelCaseMotion_iw", { noremap = true, silent = true })
            keymap("x", "iw", "<Plug>CamelCaseMotion_iw", { noremap = true, silent = true })
            keymap("o", "ib", "<Plug>CamelCaseMotion_ib", { noremap = true, silent = true })
            keymap("x", "ib", "<Plug>CamelCaseMotion_ib", { noremap = true, silent = true })
            keymap("o", "ie", "<Plug>CamelCaseMotion_ie", { noremap = true, silent = true })
            keymap("x", "ie", "<Plug>CamelCaseMotion_ie", { noremap = true, silent = true })
        end,
    },
}
