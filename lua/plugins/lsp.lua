local function is_deno_project()
    local cwd = vim.fn.getcwd()
    return vim.fn.filereadable(cwd .. "/deno.json") == 1 or vim.fn.filereadable(cwd .. "/deno.jsonc") == 1
end

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
                        client:stop(true)
                    end
                end,
            }

            lspconfig.gleam.setup {
                capabilities = capabilities,
            }

            lspconfig.jsonls.setup {
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

            lspconfig.mdx_analyzer.setup {
                capabilities = capabilities,
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
                init_options = {
                    plugins = {
                        {
                            name = "@vue/typescript-plugin",
                            location = vim.fs.joinpath(
                                vim.fs.dirname(
                                    vim.fs.dirname(vim.fn.system "echo -n $(readlink -f $(which vue-language-server))")
                                ),
                                "lib/language-tools/packages/language-server"
                            ),
                            languages = { "javascript", "typescript", "vue" },
                        },
                    },
                },
                on_attach = function(client)
                    if not is_node_dir() then
                        client:stop(true)
                    end
                    client.server_capabilities.documentFormattingProvider = false
                    client.server_capabilities.documentRangeFormattingProvider = false
                end,
                root_dir = lspconfig.util.root_pattern { "package.json", "node_modules" },
            }

            lspconfig.tsp_server.setup {
                capabilities = capabilities,
                cmd = { "pnpm", "tsp-server", "--stdio" },
            }

            lspconfig.volar.setup {}

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
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require "lint"
            lint.linters.cspell.args = vim.list_extend(lint.linters.cspell.args, {
                "--config",
                vim.fn.expand "~/.config/cspell/cspell.json",
            })
            lint.linters.luacheck.args = vim.list_extend(lint.linters.luacheck.args, {
                "--globals",
                "vim",
                "Snacks",
            })

            local function has_tool(tool_name, config_patterns)
                local bin_exists = vim.fn.filereadable("./node_modules/.bin/" .. tool_name) == 1
                if bin_exists then
                    return true
                end

                if config_patterns then
                    for _, pattern in ipairs(config_patterns) do
                        if vim.fn.filereadable(pattern) == 1 then
                            return true
                        end
                    end
                end

                return false
            end

            local function filter_available_tools(tools, config_map)
                local available = {}
                for _, tool in ipairs(tools) do
                    local config_patterns = config_map and config_map[tool] or nil
                    if has_tool(tool, config_patterns) then
                        table.insert(available, tool)
                    end
                end
                return available
            end

            local js_linters = is_deno_project() and { "deno" } or filter_available_tools { "eslint" }
            local react_linters = filter_available_tools { "eslint", "markuplint" }

            lint.linters_by_ft = {
                javascript = js_linters,
                javascriptreact = react_linters,
                lua = { "luacheck" },
                typescript = js_linters,
                typescriptreact = react_linters,
            }

            vim.api.nvim_create_autocmd({ "BufWritePost" }, {
                callback = function()
                    lint.try_lint()
                    lint.try_lint "cspell"
                end,
            })
        end,
    },
    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local js_formatters = is_deno_project() and { "deno_fmt" }
                or { "biome-check", "prettierd", "prettier", stop_after_first = true }
            require("conform").setup {
                formatters_by_ft = {
                    gleam = { "gleam" },
                    javascript = js_formatters,
                    javascriptreact = js_formatters,
                    lua = { "stylua" },
                    markdown = { "prettierd", "prettier", stop_after_first = true },
                    nix = { "nixfmt" },
                    kdl = { "kdlfmt" },
                    typescript = js_formatters,
                    typescriptreact = js_formatters,
                    vue = { "prettierd", "prettier", stop_after_first = true },
                },
                format_on_save = {
                    timeout_ms = 1000,
                    lsp_format = "fallback",
                },
            }
        end,
    },
}
