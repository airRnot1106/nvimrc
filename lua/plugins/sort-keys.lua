return {
    name = "sort-keys",
    "airRnot1106/sort-keys.nvim",
    cmd = { "SortKeys", "DeepSortKeys" },
    config = function()
        require("sort-keys").setup()
    end,
}
