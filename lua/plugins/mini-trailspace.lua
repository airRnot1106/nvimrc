return {
    name = "mini.trailspace",
    "nvim-mini/mini.trailspace",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("mini.trailspace").setup()
    end,
}
