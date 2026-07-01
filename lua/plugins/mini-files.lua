return {
    name = "mini.files",
    repo = "nvim-mini/mini.files",
    lazy = false,
    lua_source = function()
        local ignored_files = {
            ".DS_Store",
        }
        require("mini.files").setup {
            content = {
                filter = function(fs_entry)
                    return not vim.tbl_contains(ignored_files, fs_entry.name)
                end,
            },
            mappings = {
                go_in_plus = "<CR>",
            },
            windows = {
                preview = true,
            },
        }
    end,
    lua_add = function()
        vim.keymap.set("n", "<Leader>e", function()
            require("mini.files").open(vim.api.nvim_buf_get_name(0))
        end, { desc = "Open file explorer" })
        vim.keymap.set("n", "<Leader>E", function()
            require("mini.files").open()
        end, { desc = "Open file explorer (root)" })
    end,
}
