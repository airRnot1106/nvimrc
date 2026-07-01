return {
    name = "nvim-surround",
    repo = "kylechui/nvim-surround",
    on_event = { "BufReadPre", "BufNewFile" },
    lua_add = function()
        vim.g.nvim_surround_no_visual_mappings = true
    end,
    lua_source = function()
        require("nvim-surround").setup()
        vim.keymap.set("x", "S", "<Plug>(nvim-surround-visual)", {
            desc = "Add a surrounding pair around a visual selection",
        })
    end,
}
