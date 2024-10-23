return {
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        cmd = { "Telescope" },
        config = function()
            local actions = require "telescope.actions"
            require("telescope").setup {
                defaults = {
                    file_ignore_patterns = {
                        -- 検索から除外するものを指定
                        "^.git/",
                        "^.cache/",
                        "^Library/",
                        "Parallels",
                        "^Movies",
                        "^Music",
                    },
                    vimgrep_arguments = {
                        -- ripggrepコマンドのオプション
                        "rg",
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--smart-case",
                        "-uu",
                    },
                    mappings = {
                        i = {
                            ["<Esc>"] = actions.close, -- Insertモード時に <Esc> で閉じる
                        },
                        n = {
                            ["<Esc>"] = actions.close, -- Normalモード時に <Esc> で閉じる
                        },
                    },
                },
                extensions = {
                    -- ソート性能を大幅に向上させるfzfを使う
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
        event = { "BufReadPre", "BufNewFile" },
        cmd = { "Telescope" },
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        event = { "BufReadPre", "BufNewFile" },
        cmd = { "Telescope" },
    },
}
