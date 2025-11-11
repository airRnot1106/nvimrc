local check_config_file_exists = function(filenames)
    local cwd = vim.fn.getcwd()

    for _, config_file in ipairs(filenames) do
        local file_path = cwd .. "/" .. config_file
        if vim.loop.fs_stat(file_path) then
            return true
        end
    end

    return false
end

local eslint_d_condition = function()
    return check_config_file_exists {
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

local oxlint_condition = function()
    return check_config_file_exists {
        "oxlintrc.json",
        ".oxlintrc.json",
    }
end

local markuplint_condition = function()
    return check_config_file_exists {
        ".markuplintrc.json",
        ".markuplintrc.yaml",
        ".markuplintrc.yml",
        ".markuplintrc.js",
        ".markuplintrc.cjs",
        ".markuplintrc.ts",
        "markuplint.config.js",
        "markuplint.config.cjs",
        "markuplint.config.ts",
    }
end

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
                    local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })

                    if filetype == "javascript" or filetype == "typescript" then
                        -- eslint_d
                        if eslint_d_condition() then
                            lint.try_lint "eslint_d"
                        end

                        -- oxlint
                        if oxlint_condition() then
                            lint.try_lint "oxlint"
                        end
                    elseif filetype == "javascriptreact" or filetype == "typescriptreact" or filetype == "vue" then
                        -- eslint_d
                        if eslint_d_condition() then
                            lint.try_lint "eslint_d"
                        end

                        -- markuplint
                        if markuplint_condition() then
                            lint.try_lint "markuplint"
                        end

                        -- oxlint
                        if oxlint_condition() then
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
    {
        "nvimtools/none-ls.nvim",
        dependencies = {
            "nvimtools/none-ls-extras.nvim",
            "nvim-lua/plenary.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local null_ls = require "null-ls"

            null_ls.setup {
                sources = {
                    require("none-ls.code_actions.eslint_d").with {
                        condition = eslint_d_condition,
                    },
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
                    json = web_formatter,
                    jsonc = web_formatter,
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
