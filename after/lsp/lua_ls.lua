---@type vim.lsp.Config
return {
    settings = {
        Lua = {
            diagnostics = {
                globals = { "vim" },
            },
            format = {
                enable = false,
            },
            telemetry = {
                enable = false,
            },
            workspace = {
                checkThirdParty = false,
            },
        },
    },
}
