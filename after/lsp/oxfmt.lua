local utils = require "utils"

---@type vim.lsp.Config
return {
    cmd = { utils.resolve_local_bin "oxfmt", "--lsp" },
    filetypes = {
        "astro",
        "javascript",
        "javascriptreact",
        "svelte",
        "typescript",
        "typescriptreact",
        "vue",
    },
    root_markers = {
        ".git",
        "package.json",
    },
}
