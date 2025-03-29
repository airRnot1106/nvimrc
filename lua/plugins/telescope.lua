return {
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        event = { "VimEnter" },
        config = function()
            local actions = require "telescope.actions"
            require("telescope").setup {
                defaults = {
                    mappings = {
                        i = {
                            ["<Esc>"] = actions.close,
                        },
                        n = {
                            ["<Esc>"] = actions.close,
                            ["q"] = actions.close,
                        },
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },

                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown {
                            -- even more opts
                        },

                        -- pseudo code / specification for writing custom displays, like the one
                        -- for "codeactions"
                        -- specific_opts = {
                        --   [kind] = {
                        --     make_indexed = function(items) -> indexed_items, width,
                        --     make_displayer = function(widths) -> displayer
                        --     make_display = function(displayer) -> function(e)
                        --     make_ordinal = function(e) -> string
                        --   },
                        --   -- for example to disable the custom builtin "codeactions" display
                        --      do the following
                        --   codeactions = false,
                        -- }
                    },
                },
            }
            require("telescope").load_extension "fzf"
            require("telescope").load_extension "ui-select"
        end,
    },
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        event = { "VimEnter" },
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        event = { "VimEnter" },
    },
}
