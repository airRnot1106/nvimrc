return {
    name = "quicker",
    repo = "stevearc/quicker.nvim",
    on_ft = { "qf" },
    on_map = { n = { "<Leader>ql", "<Leader>ll" } },
    lua_source = function()
        require("quicker").setup {
            -- selene: allow(mixed_table)
            keys = {
                {
                    ">",
                    function()
                        require("quicker").expand { before = 2, after = 2, add_to_existing = true }
                    end,
                    desc = "Expand quickfix context",
                },
                {
                    "<",
                    function()
                        require("quicker").collapse()
                    end,
                    desc = "Collapse quickfix context",
                },
            },
        }
        vim.keymap.set("n", "<Leader>ql", function()
            require("quicker").toggle()
        end, { desc = "Toggle quickfix" })
        vim.keymap.set("n", "<Leader>ll", function()
            require("quicker").toggle { loclist = true }
        end, { desc = "Toggle loclist" })
    end,
}
