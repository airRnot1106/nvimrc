---@type vim.lsp.Config
return {
    on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, "LspStylelintFixAll", function()
            client:request_sync("workspace/executeCommand", {
                command = "stylelint.applyAutoFix",
                arguments = {
                    {
                        uri = vim.uri_from_bufnr(bufnr),
                        version = vim.lsp.util.buf_versions[bufnr],
                    },
                },
            }, nil, bufnr)
        end, {})

        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
                vim.cmd "LspStylelintFixAll"
            end,
        })
    end,
}
