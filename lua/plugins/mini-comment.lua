return {
    name = "mini.comment",
    "nvim-mini/mini.comment",
    keys = { { "<Leader>/", mode = { "n", "o", "v" } } },
    config = function()
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
