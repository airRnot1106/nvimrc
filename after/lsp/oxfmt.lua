local utils = require "utils"

---@type vim.lsp.Config
return {
    cmd = { utils.resolve_local_bin "oxfmt", "--lsp" },
    filetypes = {
        "astro",
        "css",
        "javascript",
        "javascriptreact",
        "json",
        "jsonc",
        "markdown",
        "svelte",
        "toml",
        "typescript",
        "typescriptreact",
        "vue",
        "yaml",
    },
    root_markers = {
        ".git",
        "package.json",
    },
}
