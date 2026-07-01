return {
    name = "rose-pine",
    repo = "rose-pine/neovim",
    lazy = false,
    lua_add = function()
        vim.cmd [[colorscheme rose-pine-moon]]
    end,
}
