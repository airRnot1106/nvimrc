return {
    {
        "creativenull/efmls-configs-nvim",
        version = false,
        event = { "BufReadPre", "BufNewFile" },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "Shougo/ddc-source-lsp",
            "uga-rosa/ddc-source-lsp-setup",
            "Shougo/cmdline.vim",
            "b0o/schemastore.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("ddc_source_lsp_setup").setup()
            local lspconfig = require "lspconfig"

            local capabilities = require("ddc_source_lsp").make_client_capabilities()

            local is_node_dir = function()
                return lspconfig.util.root_pattern "package.json"(vim.fn.getcwd())
            end

            lspconfig.astro.setup {
                capabilities = capabilities,
            }

            lspconfig.biome.setup {
                capabilities = capabilities,
                cmd = { "pnpm", "biome", "lsp-proxy" },
            }

            lspconfig.denols.setup {
                capabilities = capabilities,
                on_attach = function(client)
                    if is_node_dir() then
                        client.stop(true)
                    end
                end,
            }

            lspconfig.jsonls.setup {
                settings = {
                    json = {
                        schemas = require("schemastore").json.schemas {
                            select = {
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

            lspconfig.lua_ls.setup {
                capabilities = capabilities,
                settings = {
                    Lua = {
                        runtime = {
                            version = "LuaJIT",
                            pathStrict = true,
                            path = { "?.lua", "?/init.lua" },
                        },
                        diagnostics = {
                            globals = { "vim" },
                        },
                        workspace = {
                            checkThirdParty = false,
                            library = vim.list_extend(vim.api.nvim_get_runtime_file("lua", true), {
                                "${3rd}/luv/library",
                                "${3rd}/busted/library",
                                "${3rd}/luassert/library",
                            }),
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

            lspconfig.rust_analyzer.setup {
                settings = {
                    ["rust-analyzer"] = {
                        diagnostics = {
                            enable = false,
                        },
                    },
                },
            }

            lspconfig.ts_ls.setup {
                capabilities = capabilities,
                filetypes = {
                    "javascript",
                    "javascriptreact",
                    "typescript",
                    "typescriptreact",
                    "vue",
                },
                on_attach = function(client)
                    if not is_node_dir() then
                        client.stop(true)
                    end
                    client.server_capabilities.documentFormattingProvider = false
                    client.server_capabilities.documentRangeFormattingProvider = false
                end,
                root_dir = lspconfig.util.root_pattern { "package.json", "node_modules" },
                init_options = {
                    plugins = {
                        {
                            name = "@vue/typescript-plugin",
                            location = vim.env.HOME .. "/.nix-profile/lib/node_modules/@vue/language-server",
                            languages = { "javascript", "typescript", "vue" },
                        },
                    },
                },
            }

            lspconfig.volar.setup {}

            local cspell = {
                lintCommand = 'cspell --no-color --no-progress --no-summary --config ~/.config/cspell/cspell.json "${INPUT}"',
                lintFormats = { "%f:%l:%c - %m", "%f:%l:%c %m" },
                lintIgnoreExitCode = true,
                lintSeverity = 3,
                lintSource = "efm/cspell",
                lintStdin = false,
                prefix = "cspell",
            }
            local eslint = require "efmls-configs.linters.eslint"
            local kdlfmt = require "efmls-configs.formatters.kdlfmt"
            local nixfmt = require "efmls-configs.formatters.nixfmt"
            local stylua = require "efmls-configs.formatters.stylua"

            local languages = {
                astro = { cspell },
                kdl = { cspell, kdlfmt },
                lua = { cspell, stylua },
                nix = { cspell, nixfmt },
                javascript = { cspell, eslint },
                javascriptreact = { cspell, eslint },
                typescript = { cspell, eslint },
                typescriptreact = { cspell, eslint },
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
                    vim.keymap.set("n", "<F2>", "<Cmd>lua vim.lsp.buf.rename()<CR>")
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
