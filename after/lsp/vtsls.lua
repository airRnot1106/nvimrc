---@type vim.lsp.Config
return {
    on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
    settings = {
        typescript = {
            format = {
                enable = false,
            },
            suggest = {
                completeFunctionCalls = true,
            },
        },
        javascript = {
            format = {
                enable = false,
            },
            suggest = {
                completeFunctionCalls = true,
            },
        },
    },
}
