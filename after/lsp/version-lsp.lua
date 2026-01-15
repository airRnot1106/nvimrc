---@return vim.lsp.Config
return {
    cmd = { "version-lsp" },
    filetypes = { "json", "toml", "gomod", "yaml" },
    root_markers = {
        "package.json",
        "pnpm-workspace.yaml",
        "Cargo.toml",
        "go.mod",
        ".git",
    },
    settings = {
        ["version-lsp"] = {
            cache = {
                refreshInterval = 86400000, -- 24 hours (milliseconds)
            },
            registries = {
                npm = { enabled = true },
                crates = { enabled = true },
                goProxy = { enabled = true },
                github = { enabled = true },
                pnpmCatalog = { enabled = true },
            },
        },
    },
}
