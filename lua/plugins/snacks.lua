local picker_ignore_patterns = {
    ".DS_Store",
    ".direnv/*",
    ".next/*",
    "^.git/*",
    "dist/*",
    "node_modules/*",
    "package-lock.json",
}

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
                    Snacks.git.blame_line()
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

            -- picker
            {
                "<Leader>fsm",
                function()
                    Snacks.picker.smart { hidden = true, ignored = true, exclude = picker_ignore_patterns }
                end,
            },
            {
                "<Leader>fb",
                function()
                    Snacks.picker.buffers()
                end,
            },
            {
                "<Leader>fgr",
                function()
                    Snacks.picker.grep { hidden = true, ignored = true, exclude = picker_ignore_patterns }
                end,
            },
            {
                "<Leader>fch",
                function()
                    Snacks.picker.command_history()
                end,
            },
            {
                "<Leader>fno",
                function()
                    Snacks.picker "noice"
                end,
            },
            {
                "<Leader>ff",
                function()
                    Snacks.picker.smart { hidden = true, ignored = true, exclude = picker_ignore_patterns }
                end,
            },
            {
                "<Leader>fgf",
                function()
                    Snacks.picker.git_files()
                end,
            },
            {
                "<Leader>fpj",
                function()
                    Snacks.picker.projects()
                end,
            },
            {
                "<Leader>frc",
                function()
                    Snacks.picker.recent()
                end,
            },
            {
                "<Leader>fgb",
                function()
                    Snacks.picker.git_branches()
                end,
            },
            {
                "<Leader>fsh",
                function()
                    Snacks.picker.search_history()
                end,
            },
            {
                "<Leader>fdi",
                function()
                    Snacks.picker.diagnostics()
                end,
            },
            {
                "<Leader>fql",
                function()
                    Snacks.picker.qflist()
                end,
            },
            {
                "<Leader>fld",
                function()
                    Snacks.picker.lsp_definitions()
                end,
            },
            {
                "<Leader>flr",
                function()
                    Snacks.picker.lsp_references()
                end,
                nowait = true,
            },
            {
                "<Leader>fre",
                function()
                    Snacks.picker.resume()
                end,
            },
            {
                "<Leader>fpi",
                function()
                    Snacks.picker.pickers()
                end,
            },

            -- scratch
            {
                "<Leader>cr",
                function()
                    Snacks.scratch.open()
                end,
            },

            -- terminal
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
                picker = {
                    ui_select = true,
                },
            }
            vim.ui.input = Snacks.input.input
            vim.ui.select = Snacks.picker.select
        end,
    },
}
