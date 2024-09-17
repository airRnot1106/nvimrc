return {
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        event = { "BufReadPre", "BufNewFile" },
        opts = {},
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "Shougo/ddc-source-lsp",
            "uga-rosa/ddc-source-lsp-setup",
            "creativenull/efmls-configs-nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("ddc_source_lsp_setup").setup()
            local capabilities = require("ddc_source_lsp").make_client_capabilities()

            local lspconfig = require "lspconfig"

            lspconfig.lua_ls.setup {
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" },
                        },
                        workspace = {
                            checkThirdParty = false,
                        },
                        format = {
                            enable = false,
                        },
                    },
                },
            }

            local stylua = require "efmls-configs.formatters.stylua"
            local languages = {
                lua = { stylua },
            }
            lspconfig.efm.setup {
                capabilities = capabilities,
                filetypes = vim.tbl_keys(languages),
                init_options = {
                    documentFormatting = true,
                    documentRangeFormatting = true,
                },
                settings = {
                    rootMarkers = { ".git/" },
                    languages = languages,
                },
            }

            local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
            vim.api.nvim_create_autocmd("LspAttach", {
                group = augroup,
                callback = function(ev)
                    vim.keymap.set("n", "<C-k>", "<cmd>lua vim.lsp.buf.hover()<CR>")
                    vim.keymap.set("n", "gf", "<cmd>lua vim.lsp.buf.format({ async = false })<CR>")
                    vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
                    vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
                    vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
                    vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
                    vim.keymap.set("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
                    vim.keymap.set("n", "gn", "<cmd>lua vim.lsp.buf.rename()<CR>")
                    vim.keymap.set("n", "<Leader>.", "<cmd>lua vim.lsp.buf.code_action()<CR>")
                    vim.keymap.set("n", "ge", "<cmd>lua vim.diagnostic.open_float()<CR>")
                    vim.keymap.set("n", "g]", "<cmd>lua vim.diagnostic.goto_next()<CR>")
                    vim.keymap.set("n", "g[", "<cmd>lua vim.diagnostic.goto_prev()<CR>")

                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    if client == nil then
                        return
                    end

                    if client.supports_method "textDocument/formatting" then
                        vim.api.nvim_clear_autocmds { group = augroup, buffer = ev.bufnr }
                        vim.api.nvim_create_autocmd({ "BufWritePre" }, {
                            group = augroup,
                            buffer = ev.bufnr,
                            callback = function()
                                vim.lsp.buf.format { async = false }
                            end,
                        })
                    end
                end,
            })

            vim.lsp.handlers["textDocument/publishDiagnostics"] =
                vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = false })
        end,
    },
}
