return {
    name = "fuzzy-motion",
    repo = "yuki-yano/fuzzy-motion.vim",
    depends = { "kensaku" },
    on_cmd = { "FuzzyMotion" },
    on_map = { n = { "<Leader>;" }, x = { "<Leader>;" } },
    lua_add = function()
        vim.g["fuzzy_motion_matchers"] = { "kensaku", "fzf" }
    end,
    lua_source = function()
        vim.keymap.set(
            { "n", "x" },
            "<Leader>;",
            "<Cmd>FuzzyMotion<CR>",
            { desc = "Enable FuzzyMotion", silent = true }
        )
    end,
}
