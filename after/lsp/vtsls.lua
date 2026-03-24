local vue_plugin = {
    name = "@vue/typescript-plugin",
    location = vim.fs.joinpath(
        vim.fs.dirname(vim.fs.dirname(vim.fn.system "echo -n $(readlink -f $(which vue-language-server))")),
        "lib/language-tools/packages/language-server"
    ),
    languages = { "vue" },
    configNamespace = "typescript",
}

---@type vim.lsp.Config
return {
    cmd = { "vtsls", "--stdio" },
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
    },
    settings = {
        vtsls = {
            tsserver = {
                globalPlugins = {
                    vue_plugin,
                },
            },
        },
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
