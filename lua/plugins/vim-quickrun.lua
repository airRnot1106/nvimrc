return {
    name = "vim-quickrun",
    repo = "thinca/vim-quickrun",
    on_cmd = { "QuickRun" },
    on_map = { nv = { "<Leader>r" } },
    lua_add = function()
        vim.g.quickrun_no_default_key_mappings = 1
    end,
    lua_source = function()
        vim.keymap.set({ "n", "v" }, "<Leader>r", "<Cmd>QuickRun<CR>", { desc = "Run code" })
        vim.g.quickrun_config = {
            ["_"] = {
                ["outputter/buffer/split"] = ":botright 15split",
                ["outputter/buffer/close_on_empty"] = 1,
            },
        }
    end,
}
