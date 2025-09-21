---@type vim.lsp.Config
return {
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
    },
    init_options = {
        plugins = {
            {
                name = "@vue/typescript-plugin",
                location = vim.fs.joinpath(
                    vim.fs.dirname(vim.fs.dirname(vim.fn.system "echo -n $(readlink -f $(which vue-language-server))")),
                    "lib/language-tools/packages/language-server"
                ),
                languages = { "javascript", "typescript", "vue" },
            },
        },
    },
    on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
    root_dir = function(bufnr, callback)
        local found_dirs = vim.fs.find({
            "package.json",
        }, {
            upward = true,
            path = vim.fs.dirname(vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))),
        })
        if #found_dirs > 0 then
            return callback(vim.fs.dirname(found_dirs[1]))
        end
    end,
}
