return {
    name = "fuzzy-motion",
    "yuki-yano/fuzzy-motion.vim",
    dependencies = { "kensaku" },
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
