return {
    name = "goda.vim",
    "Shougo/goda.vim",
    lazy = true,
    init = function()
        local root = require("lazy.core.config").options.root
        vim.g["goda#workspace"] = { root .. "/goda.vim", root .. "/goda-cmp" }
    end,
    build = function()
        local plugin = require("lazy.core.config").plugins["goda-cmp"]
        if plugin and plugin._.installed then
            require("lazy").load { plugins = { "goda-cmp" } }
            vim.fn["goda_cmp#build"]()
        end
    end,
}
