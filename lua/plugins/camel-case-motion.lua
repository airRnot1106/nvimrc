return {
    {
        "bkad/CamelCaseMotion",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local keymap = vim.api.nvim_set_keymap
            keymap("n", "[w", "<Plug>CamelCaseMotion_w", { noremap = true, silent = true })
            keymap("x", "[w", "<Plug>CamelCaseMotion_w", { noremap = true, silent = true })
            keymap("n", "[b", "<Plug>CamelCaseMotion_b", { noremap = true, silent = true })
            keymap("x", "[b", "<Plug>CamelCaseMotion_b", { noremap = true, silent = true })
            keymap("n", "[e", "<Plug>CamelCaseMotion_e", { noremap = true, silent = true })
            keymap("x", "[e", "<Plug>CamelCaseMotion_e", { noremap = true, silent = true })
            keymap("o", "ciw", "<Plug>CamelCaseMotion_iw", { noremap = true, silent = true })
            keymap("x", "ciw", "<Plug>CamelCaseMotion_iw", { noremap = true, silent = true })
            keymap("o", "cib", "<Plug>CamelCaseMotion_ib", { noremap = true, silent = true })
            keymap("x", "cib", "<Plug>CamelCaseMotion_ib", { noremap = true, silent = true })
            keymap("o", "cie", "<Plug>CamelCaseMotion_ie", { noremap = true, silent = true })
            keymap("x", "cie", "<Plug>CamelCaseMotion_ie", { noremap = true, silent = true })
        end,
    },
}
