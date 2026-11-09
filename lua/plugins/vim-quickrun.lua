return {
    name = "vim-quickrun",
    "thinca/vim-quickrun",
    cmd = { "QuickRun" },
    keys = { { "<Leader>r", mode = { "n", "v" } } },
    init = function()
        vim.g.quickrun_no_default_key_mappings = 1
    end,
    config = function()
        vim.keymap.set({ "n", "v" }, "<Leader>r", "<Cmd>QuickRun<CR>", { desc = "Run code" })
        vim.g.quickrun_config = {
            ["_"] = {
                ["outputter/buffer/split"] = ":botright 15split",
                ["outputter/buffer/close_on_empty"] = 1,
            },
        }
    end,
}
