return {
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
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
                },
            }
            require("telescope").load_extension "fzf"
        end,
    },
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
    },
}
