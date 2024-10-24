return {
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

            lspconfig.astro.setup {
                capabilities = capabilities,
            }

            lspconfig.biome.setup {
                capabilities = capabilities,
                cmd = { "pnpm", "biome", "lsp-proxy" },
            }

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

            lspconfig.nil_ls.setup {
                capabilities = capabilities,
            }

            -- lspconfig.tailwindcss.setup {
            --     capabilities = capabilities,
            -- }

            lspconfig.ts_ls.setup {
                capabilities = capabilities,
                on_attach = function(client)
                    client.server_capabilities.documentFormattingProvider = false
                    client.server_capabilities.documentRangeFormattingProvider = false
                end,
            }

            local kdlfmt = {
                formatCommand = "kdlfmt format -",
                formatStdin = true,
            }
            local eslint = require "efmls-configs.linters.eslint"
            local nixfmt = require "efmls-configs.formatters.nixfmt"
            local prettier = require "efmls-configs.formatters.prettier"
            local stylua = require "efmls-configs.formatters.stylua"
            local languages = {
                astro = { prettier },
                kdl = { kdlfmt },
                lua = { stylua },
                nix = { nixfmt },
                javascript = { eslint },
                javascriptreact = { eslint },
                typescript = { eslint },
                typescriptreact = { eslint },
            }
            local efmls_config = {
                filetypes = vim.tbl_keys(languages),
                settings = {
                    rootMarkers = { ".git/" },
                    languages = languages,
                },
                init_options = {
                    documentFormatting = true,
                    documentRangeFormatting = true,
                    -- hover = true,
                    -- documentSymbol = true,
                    -- codeAction = true,
                    -- completion = true,
                },
            }
            lspconfig.efm.setup(vim.tbl_extend("force", efmls_config, {
                capabilities = capabilities,
            }))

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
                    vim.keymap.set("n", "<F2>", function()
                        vim.fn["cmdline#enable"]()
                        vim.lsp.buf.rename()
                    end)
                    vim.keymap.set("n", "<Leader>.", "<Cmd>lua vim.lsp.buf.code_action()<CR>")
                    vim.keymap.set("n", "ge", "<Cmd>lua vim.diagnostic.open_float()<CR>")
                    vim.keymap.set("n", "g]", "<Cmd>lua vim.diagnostic.goto_next()<CR>")
                    vim.keymap.set("n", "g[", "<Cmd>lua vim.diagnostic.goto_prev()<CR>")

                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    if client == nil then
                        return
                    end
                    if not client.supports_method "textDocument/formatting" then
                        return
                    end

                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = ev.buffer,
                        group = augroup,
                        callback = function()
                            vim.lsp.buf.format { async = false }
                        end,
                    })
                end,
            })

            vim.lsp.handlers["textDocument/publishDiagnostics"] =
                vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = true })
        end,
    },
}
