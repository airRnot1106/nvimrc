return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        ---@type snacks.Config
        opts = {
            git = {
                enabled = true,
            },
            input = {
                enabled = true,
            },
            lazygit = {
                enabled = true,
            },
            picker = {
                enabled = true,
                ui_select = true,
            },
            rename = {
                enabled = true,
            },
            scratch = {
                enabled = true,
            },
        },
        keys = {
            -- git
            {
                "<Leader>gbl",
                function()
                    Snacks.git.blame_line()
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
                    Snacks.picker.smart { hidden = true, ignored = true }
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
                    Snacks.picker.grep { hidden = true, ignored = true }
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
                    Snacks.picker.smart { hidden = true, ignored = true }
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
                "<Leader>sc",
                function()
                    Snacks.scratch.open()
                end,
            },
        },
        config = function()
            require("snacks").setup()
        end,
    },
}
