return {
    name = "mini.comment",
    repo = "nvim-mini/mini.comment",
    on_map = { nvo = { "<Leader>/" } },
    lua_source = function()
        require("mini.comment").setup {
            mappings = {
                comment = "<Leader>/",
                comment_line = "<Leader>/",
                comment_visual = "<Leader>/",
                textobject = "<Leader>/",
            },
        }
    end,
}
