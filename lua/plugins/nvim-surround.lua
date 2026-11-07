return {
    name = "nvim-surround",
    "kylechui/nvim-surround",
    event = { "BufReadPre", "BufNewFile" },
    init = function()
        vim.g.nvim_surround_no_visual_mappings = true
    end,
    config = function()
        require("nvim-surround").setup()
        vim.keymap.set("x", "S", "<Plug>(nvim-surround-visual)", {
            desc = "Add a surrounding pair around a visual selection",
        })
    end,
}
