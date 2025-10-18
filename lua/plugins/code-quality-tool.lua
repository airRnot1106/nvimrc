return {
    -- Linter
    {
        "nvimtools/none-ls.nvim",
        dependencies = {
            "nvimtools/none-ls-extras.nvim",
            "davidmh/cspell.nvim",
            "nvim-lua/plenary.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local null_ls = require "null-ls"

            local cspell = require "cspell"

            local eslint_condition = function(utils)
                return utils.root_has_file {
                    "eslint.config.js",
                    "eslint.config.mjs",
                    "eslint.config.cjs",
                    "eslint.config.ts",
                    "eslint.config.mts",
                    "eslint.config.cts",
                    -- deprecated
                    ".eslintrc.js",
                    ".eslintrc.cjs",
                    ".eslintrc.yaml",
                    ".eslintrc.yml",
                    ".eslintrc.json",
                    ".eslintrc",
                }
            end

            null_ls.setup {
                sources = {
                    -- cspell
                    cspell.diagnostics.with {
                        diagnostics_postprocess = function(diagnostic)
                            diagnostic.severity = vim.diagnostic.severity.HINT
                        end,
                        extra_args = { "--config", vim.fn.expand "~/.config/cspell/cspell.json" },
                    },
                    -- javascript/typescript
                    require("none-ls.diagnostics.eslint_d").with {
                        condition = eslint_condition,
                    },
                    require("none-ls.code_actions.eslint_d").with {
                        condition = eslint_condition,
                    },
                    null_ls.builtins.diagnostics.markuplint.with {
                        condition = function(utils)
                            return utils.root_has_file {
                                ".markuplintrc",
                                ".markuplintrc.json",
                                ".markuplintrc.yaml",
                                ".markuplintrc.yml",
                            }
                        end,
                    },
                    -- lua
                    null_ls.builtins.diagnostics.selene,
                    -- python
                    null_ls.builtins.diagnostics.mypy,
                    -- textlint
                    null_ls.builtins.diagnostics.textlint.with { filetypes = { "markdown" } },
                    null_ls.builtins.code_actions.textlint.with { filetypes = { "markdown" } },
                },
            }
        end,
    },
    -- Formatter
    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local function is_deno_project()
                local cwd = vim.fn.getcwd()
                return vim.fn.filereadable(cwd .. "/deno.json") == 1
                    or vim.fn.filereadable(cwd .. "/deno.jsonc") == 1
                    or vim.fn.filereadable(cwd .. "/deps.ts") == 1
            end
            local web_formatter = function()
                if is_deno_project() then
                    -- Denoプロジェクトの場合はLSP(denols)のフォーマットを使う (fallback)
                    return {}
                end
                return { "biome-check", "prettierd", "prettier", stop_after_first = true }
            end

            require("conform").setup {
                formatters_by_ft = {
                    gleam = { "gleam" },
                    javascript = web_formatter,
                    javascriptreact = web_formatter,
                    lua = { "stylua" },
                    markdown = { "prettierd", "prettier", stop_after_first = true },
                    nix = { "nixfmt" },
                    kdl = { "kdlfmt" },
                    python = { "ruff" },
                    typescript = web_formatter,
                    typescriptreact = web_formatter,
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
