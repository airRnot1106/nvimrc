---@type vim.lsp.Config
return {
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
