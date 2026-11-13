return {
    name = "goda-cmp",
    "Shougo/goda-cmp.vim",
    dependencies = { "goda.vim", "nvim-autopairs", "pum", "goda-cmp-ui-pum" },
    event = { "CmdlineChanged", "CmdlineEnter", "InsertEnter", "TextChangedI", "TextChangedP" },
    build = ":call goda_cmp#build()",
    config = function()
        vim.fn["pum#set_option"] {
            padding = true,
            preview = true,
            previewer = "goda_cmp#get_previewer",
            preview_delay = 100,
            preview_width = 80,
            preview_border = "rounded",
        }

        vim.api.nvim_create_autocmd("User", {
            pattern = "PumPreview",
            callback = function()
                local win = vim.fn.win_findbuf(vim.fn["pum#get_preview_buf"]())[1]
                if win then
                    vim.wo[win].conceallevel = 2
                end
            end,
        })

        vim.fn["goda_cmp#enable"]()

        local function pum_or(rhs, fallback)
            return function()
                return vim.fn["pum#visible"]() and rhs or fallback
            end
        end

        vim.keymap.set(
            "i",
            "<C-n>",
            pum_or("<Cmd>call pum#map#insert_relative(+1)<CR>", "<C-n>"),
            { expr = true, desc = "Completion next" }
        )
        vim.keymap.set(
            "i",
            "<C-p>",
            pum_or("<Cmd>call pum#map#insert_relative(-1)<CR>", "<C-p>"),
            { expr = true, desc = "Completion previous" }
        )
        vim.keymap.set("i", "<CR>", function()
            if vim.fn["pum#visible"]() and vim.fn["pum#entered"]() then
                return vim.api.nvim_replace_termcodes("<Cmd>call pum#map#confirm()<CR>", true, true, true)
            end
            return require("nvim-autopairs").autopairs_cr()
        end, { expr = true, replace_keycodes = false, desc = "Completion confirm / autopairs CR" })
        vim.keymap.set(
            "i",
            "<C-e>",
            pum_or("<Cmd>call pum#map#cancel()<CR>", "<C-e>"),
            { expr = true, desc = "Completion cancel" }
        )

        local function commandline_pre()
            local maps = {
                ["<C-n>"] = "+1",
                ["<C-p>"] = "-1",
            }
            for lhs, delta in pairs(maps) do
                vim.keymap.set(
                    "c",
                    lhs,
                    "<Cmd>call pum#map#insert_relative(" .. delta .. ")<CR>",
                    { desc = "Cmdline completion" }
                )
            end
            vim.keymap.set("c", "<C-y>", "<Cmd>call pum#map#confirm()<CR>", { desc = "Cmdline confirm" })
            vim.keymap.set("c", "<C-e>", "<Cmd>call pum#map#cancel()<CR>", { desc = "Cmdline cancel" })

            vim.api.nvim_create_autocmd("User", {
                pattern = "GodaCmpCmdlineLeave",
                once = true,
                callback = function()
                    for lhs in pairs(maps) do
                        pcall(vim.keymap.del, "c", lhs)
                    end
                    pcall(vim.keymap.del, "c", "<C-y>")
                    pcall(vim.keymap.del, "c", "<C-e>")
                end,
            })

            vim.fn["goda_cmp#enable_cmdline"]()
        end

        vim.keymap.set({ "n", "x" }, ":", function()
            commandline_pre()
            return ":"
        end, { expr = true, desc = "Cmdline completion" })
    end,
}
