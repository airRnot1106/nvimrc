return {
    name = "gfm",
    "airRnot1106/gfm.vim",
    dependencies = { "goda.vim", "gks" },
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
