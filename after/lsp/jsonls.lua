---@type vim.lsp.Config
return {
    on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
    settings = {
        json = {
            schemas = require("schemastore").json.schemas {
                select = {
                    "Biome Formatter Config",
                    "CSpell (cspell.json)",
                    ".eslintrc",
                    "package.json",
                    "tsconfig.json",
                },
            },
            validate = { enable = true },
        },
    },
}
