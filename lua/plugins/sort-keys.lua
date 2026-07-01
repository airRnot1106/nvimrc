return {
    name = "sort-keys",
    repo = "airRnot1106/sort-keys.nvim",
    on_cmd = { "SortKeys", "DeepSortKeys" },
    lua_source = function()
        require("sort-keys").setup()
    end,
}
