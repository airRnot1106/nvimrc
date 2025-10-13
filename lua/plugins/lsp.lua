return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "Shougo/ddc-source-lsp",
            "uga-rosa/ddc-source-lsp-setup",
            "b0o/schemastore.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("ddc_source_lsp_setup").setup {
                override_capabilities = true,
                respect_trigger = true,
            }

            ---@type vim.lsp.Config
            vim.lsp.config("*", {
                capabilities = require("ddc_source_lsp").make_client_capabilities(),
            })

            local lsp_names = {
                "astro",
                "biome",
                "denols",
                "gleam",
                "jsonls",
                "lua_ls",
                "mdx_analyzer",
                "nil_ls",
                "pylsp",
                "rust_analyzer",
                "ts_ls",
                "tsp_server",
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
