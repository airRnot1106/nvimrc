return {
    {
        "nvim-telescope/telescope.nvim",
        version = "*",
        dependencies = {
            "nvim-lua/plenary.nvim",
            -- optional but recommended
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "danielfalk/smart-open.nvim",
            "nvim-tree/nvim-web-devicons",
            "kkharji/sqlite.lua",
        },
        events = { "VeryLazy" },
        config = function()
            -- setup telescope
            require("telescope").setup {
                defaults = {
                    mappings = {
                        i = {
                            ["<C-y>"] = function()
                                -- enable skkeleton before input
                                vim.api.nvim_feedkeys(
                                    vim.api.nvim_replace_termcodes("<Plug>(skkeleton-enable)", true, false, true),
                                    "m",
                                    false
                                )
                                vim.ui.input({ prompt = "> " }, function(input)
                                    if input then
                                        vim.api.nvim_feedkeys(input, "n", false)
                                    end
                                end)
                            end,
                        },
                        n = {
                            q = require("telescope.actions").close,
                        },
                    },
                },
            }

            -- load extensions
            local load_extension = require("telescope").load_extension
            load_extension "notify"

            -- configure sqlite
            vim.g.sqlite_clib_path = "/usr/lib/libsqlite3.dylib"
            load_extension "smart_open"

            -- register keymaps
            local builtin = require "telescope.builtin"
            local extensions = require("telescope").extensions
            vim.keymap.set("n", "<Leader>ff", extensions.smart_open.smart_open, { desc = "Telescope smart open" })
            vim.keymap.set("n", "<Leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
            vim.keymap.set("n", "<Leader>fb", builtin.buffers, { desc = "Telescope buffers" })
            vim.keymap.set("n", "<Leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
            vim.keymap.set("n", "<Leader>fc", builtin.command_history, { desc = "Telescope command history" })
            vim.keymap.set("n", "<Leader>fk", builtin.keymaps, { desc = "Telescope keymaps" })
            vim.keymap.set("n", "<Leader>fr", builtin.resume, { desc = "Telescope resume" })
            vim.keymap.set("n", "<Leader>fp", builtin.pickers, { desc = "Telescope pickers" })
            vim.keymap.set("n", "<Leader>fd", builtin.diagnostics, { desc = "Telescope diagnostics" })
            vim.keymap.set("n", "<Leader>fld", builtin.lsp_definitions, { desc = "Telescope LSP definitions" })
            vim.keymap.set("n", "<Leader>flr", builtin.lsp_references, { desc = "Telescope LSP references" })
            vim.keymap.set("n", "<Leader>fli", builtin.lsp_implementations, { desc = "Telescope LSP implementations" })
            vim.keymap.set("n", "<Leader>fn", extensions.notify.notify, { desc = "Telescope notify" })
        end,
    },
}
