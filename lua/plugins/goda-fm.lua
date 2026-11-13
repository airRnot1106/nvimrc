return {
    name = "goda-fm",
    "airRnot1106/goda-fm.vim",
    dependencies = { "goda.vim", "goda-ks" },
    build = "nix build",
    cmd = { "FuzzyMotion" },
    keys = { { "<Leader>;", mode = { "n", "x" } } },
    init = function()
        vim.g["fuzzy_motion_matchers"] = { "kensaku", "fzf" }
    end,
    config = function()
        vim.keymap.set(
            { "n", "x" },
            "<Leader>;",
            "<Cmd>FuzzyMotion<CR>",
            { desc = "Enable FuzzyMotion", silent = true }
        )
    end,
}
