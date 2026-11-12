return {
    name = "nvim-ts-autotag",
    "windwp/nvim-ts-autotag",
    -- the filetypes nvim-ts-autotag ships tag configs and aliases for
    ft = {
        "astro",
        "blade",
        "dot",
        "elixir",
        "eruby",
        "glimmer",
        "handlebars",
        "hbs",
        "heex",
        "html",
        "htmlangular",
        "htmldjango",
        "javascript",
        "javascript.glimmer",
        "javascript.jsx",
        "javascriptreact",
        "liquid",
        "markdown",
        "php",
        "rescript",
        "rust",
        "svelte",
        "templ",
        "twig",
        "typescript",
        "typescript.glimmer",
        "typescript.tsx",
        "typescriptreact",
        "vento",
        "vue",
        "xml",
    },
    config = function()
        require("nvim-ts-autotag").setup {
            opts = {
                enable_close = true, -- Auto close tags
                enable_rename = true, -- Auto rename pairs of tags
                enable_close_on_slash = true, -- Auto close on trailing </
            },
        }
    end,
}
