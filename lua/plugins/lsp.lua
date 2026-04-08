return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "b0o/schemastore.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            ---@type vim.lsp.Config
            vim.lsp.config("*", {
                capabilities = require("blink.cmp").get_lsp_capabilities {
                    textDocument = {
                        completion = {
                            completionItem = {
                                snippetSupport = true,
                            },
                        },
                        foldingRange = {
                            dynamicRegistration = false,
                            lineFoldingOnly = true,
                        },
                    },
                },
            })

            local lsp_names = {
                "astro",
                "biome",
                "denols",
                "eslint",
                "gleam",
                "gopls",
                "jsonls",
                "lua_ls",
                "mdx_analyzer",
                "nixd",
                "oxfmt",
                "oxlint",
                "pylsp",
                "rust_analyzer",
                "tailwindcss",
                "tsp_server",
                "version-lsp",
                "vtsls",
                "vue_ls",
                "yamlls",
            }

            vim.lsp.enable(lsp_names)

            local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
            vim.api.nvim_create_autocmd("LspAttach", {
                group = augroup,
                callback = function(ev)
                    vim.keymap.set("n", "<C-k>", "<Cmd>lua vim.lsp.buf.hover()<CR>")
                    vim.keymap.set("n", "gf", "<Cmd>lua vim.lsp.buf.format({ async = false })<CR>")
                    vim.keymap.set("n", "gr", "<Cmd>lua vim.lsp.buf.references()<CR>")
                    vim.keymap.set("n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>")
                    vim.keymap.set("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>")
                    vim.keymap.set("n", "gi", "<Cmd>lua vim.lsp.buf.implementation()<CR>")
                    vim.keymap.set("n", "gt", "<Cmd>lua vim.lsp.buf.type_definition()<CR>")
                    vim.keymap.set("n", "<F2>", "<Cmd>lua vim.lsp.buf.rename()<CR>")
                    vim.keymap.set("n", "<Leader>.", "<Cmd>lua vim.lsp.buf.code_action()<CR>")
                    vim.keymap.set("n", "ge", "<Cmd>lua vim.diagnostic.open_float()<CR>")
                    vim.keymap.set("n", "g]", "<Cmd>lua vim.diagnostic.jump({ count = 1, float = true })<CR>")
                    vim.keymap.set("n", "g[", "<Cmd>lua vim.diagnostic.jump({ count = -1, float = true})<CR>")

                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    if client == nil then
                        return
                    end
                end,
            })

            vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx)
                vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
            end
        end,
    },
}
