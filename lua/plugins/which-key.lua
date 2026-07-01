return {
    name = "which-key",
    repo = "folke/which-key.nvim",
    on_map = { n = { "<Leader>?" }, i = { "<C-x>" } },
    lua_source = function()
        local wk = require "which-key"

        -- selene: allow(mixed_table)
        wk.setup {
            triggers = {
                { "<auto>", mode = "nxso" },
                { "<C-x>", mode = "i" },
            },
        }

        -- :h ins-completion
        -- selene: allow(mixed_table)
        wk.add {
            mode = { "i" },
            { "<C-x><C-]>", desc = "tags" },
            { "<C-x><C-d>", desc = "definitions or macros" },
            { "<C-x><C-f>", desc = "file names" },
            { "<C-x><C-i>", desc = "keywords in the current and included files" },
            { "<C-x><C-k>", desc = "keywords in dictionary" },
            { "<C-x><C-l>", desc = "Whole lines" },
            { "<C-x><C-n>", desc = "keywords in the current file" },
            { "<C-x><C-o>", desc = "omni completion" },
            { "<C-x><C-s>", desc = "Spelling suggestions" },
            { "<C-x><C-t>", desc = "keywords in thesaurus" },
            { "<C-x><C-u>", desc = "User defined completion" },
            { "<C-x><C-v>", desc = "Vim command-line" },
            { "<C-x><C-z>", desc = "stop completion" },
        }

        vim.keymap.set("n", "<Leader>?", function()
            -- which-key defers its own post-setup() init via vim.schedule;
            -- scheduling this too guarantees it runs after that, not before.
            vim.schedule(function()
                require("which-key").show { global = false }
            end)
        end, { desc = "WhichKey" })
    end,
}
