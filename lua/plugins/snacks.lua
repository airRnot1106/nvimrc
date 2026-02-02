return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        ---@type snacks.Config
        keys = {
            -- git
            {
                "<Leader>gbl",
                function()
                    local file = vim.api.nvim_buf_get_name(0)
                    Snacks.terminal.open { "blake", file }
                end,
            },

            -- gitbrowse
            {
                "<Leader>gop",
                function()
                    Snacks.gitbrowse.open()
                end,
            },

            -- lazygit
            {
                "<Leader>lg",
                function()
                    Snacks.lazygit.open()
                end,
            },

            -- terminal
            {
                "<F7>",
                function()
                    Snacks.terminal.toggle(nil, {
                        win = {
                            position = "float",
                            relative = "editor",
                            border = "bold",
                        },
                        start_insert = true,
                        auto_insert = false,
                    })
                end,
                mode = { "n", "i", "t" },
            },
            {
                "<Leader>tv",
                function()
                    Snacks.terminal.open(nil, {
                        win = {
                            position = "right",
                            relative = "editor",
                        },
                        start_insert = false,
                        auto_insert = false,
                    })
                end,
            },
            {
                "<Leader>ts",
                function()
                    Snacks.terminal.open(nil, {
                        win = {
                            position = "bottom",
                            relative = "editor",
                        },
                        start_insert = false,
                        auto_insert = false,
                    })
                end,
            },
        },
        config = function()
            require("snacks").setup {
                lazygit = {
                    config = {
                        os = {
                            edit = '[ -z "$NVIM" ] && (nvim -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote {{filename}})',
                            editAtLine = '[ -z "$NVIM" ] && (nvim +{{line}} -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q" &&  nvim --server "$NVIM" --remote {{filename}} && nvim --server "$NVIM" --remote-send ":{{line}}<CR>")',
                            editAtLineAndWait = "nvim +{{line}} {{filename}}",
                            openDirInEditor = '[ -z "$NVIM" ] && (nvim -- {{dir}}) || (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote {{dir}})',
                        },
                    },
                },
            }
            vim.ui.input = Snacks.input.input
            vim.ui.select = Snacks.picker.select
        end,
    },
}
