return {
    -- Linter
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require "lint"

            lint.linters.cspell.args = vim.list_extend(lint.linters.cspell.args, {
                "--config",
                vim.fn.expand "~/.config/cspell/cspell.json",
            })

            lint.linters.oxlint.args = { "--type-aware", "--format", "github" }

            lint.linters_by_ft = {
                go = { "golangcilint" },
                javascript = { "eslint_d", "oxlint" },
                javascriptreact = { "eslint_d", "markuplint", "oxlint" },
                lua = { "selene" },
                markdown = { "markdownlint-cli2" },
                python = { "ruff" },
                typescript = { "eslint_d", "oxlint" },
                typescriptreact = { "eslint_d", "markuplint", "oxlint" },
                vue = { "eslint_d", "oxlint" },
            }

            local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
                group = lint_augroup,
                callback = function(args)
                    local utils = require "utils"
                    local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })

                    if filetype == "javascript" or filetype == "typescript" then
                        if utils.has_local_bin "eslint" then
                            lint.try_lint "eslint_d"
                        end

                        if utils.has_local_bin "oxlint" then
                            lint.try_lint "oxlint"
                        end
                    elseif filetype == "javascriptreact" or filetype == "typescriptreact" or filetype == "vue" then
                        if utils.has_local_bin "eslint" then
                            lint.try_lint "eslint_d"
                        end

                        if utils.has_local_bin "markuplint" then
                            lint.try_lint "markuplint"
                        end

                        if utils.has_local_bin "oxlint" then
                            lint.try_lint "oxlint"
                        end
                    else
                        lint.try_lint()
                    end

                    lint.try_lint "cspell"
                end,
            })
        end,
    },
    -- Formatter
    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local utils = require "utils"
            local function is_deno_project()
                local cwd = vim.fn.getcwd()
                return vim.fn.filereadable(cwd .. "/deno.json") == 1
                    or vim.fn.filereadable(cwd .. "/deno.jsonc") == 1
                    or vim.fn.filereadable(cwd .. "/deps.ts") == 1
            end
            local web_formatter = function(opts)
                opts = opts or {}
                return function()
                    if is_deno_project() then
                        -- Denoプロジェクトの場合はLSP(denols)のフォーマットを使う (fallback)
                        return {}
                    end

                    local formatters = {}
                    if utils.has_local_bin "biome" then
                        table.insert(formatters, "biome-check")
                    end
                    if utils.has_local_bin "prettier" then
                        table.insert(formatters, "prettierd")
                    end
                    if opts.stop_after_first then
                        formatters.stop_after_first = true
                    end
                    return formatters
                end
            end

            require("conform").setup {
                formatters_by_ft = {
                    gleam = { "gleam" },
                    go = { "gofumpt" },
                    javascript = web_formatter { stop_after_first = true },
                    javascriptreact = web_formatter { stop_after_first = true },
                    json = web_formatter { stop_after_first = true },
                    jsonc = web_formatter { stop_after_first = true },
                    kdl = { "kdlfmt" },
                    lua = { "stylua" },
                    markdown = web_formatter { stop_after_first = true },
                    nix = { "nixfmt" },
                    python = { "ruff" },
                    typescript = web_formatter { stop_after_first = true },
                    typescriptreact = web_formatter { stop_after_first = true },
                    vue = web_formatter { stop_after_first = true },
                },
                format_on_save = {
                    timeout_ms = 1000,
                    lsp_format = "first",
                },
            }
        end,
    },
}
