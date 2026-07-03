return {
    name = "nvim-lint",
    repo = "mfussenegger/nvim-lint",
    on_event = { "BufReadPre", "BufNewFile" },
    lua_source = function()
        local lint = require "lint"

        lint.linters.cspell.args = vim.list_extend(lint.linters.cspell.args, {
            "--config",
            vim.fn.expand "~/.config/cspell/cspell.json",
        })

        lint.linters_by_ft = {
            astro = { "oxlint" },
            bash = { "shellcheck" },
            ghactions = { "actionlint", "zizmor" },
            go = { "golangcilint" },
            javascript = { "eslint_d" },
            javascriptreact = { "eslint_d", "markuplint", "oxlint" },
            lua = { "selene" },
            nix = { "nix" },
            python = { "ruff" },
            rust = { "clippy" },
            sh = { "shellcheck" },
            typescript = { "eslint_d", "deno" },
            typescriptreact = { "eslint_d", "markuplint", "oxlint", "deno" },
        }

        local root_markers_by_linter = {
            deno = { "deno.json", "deno.jsonc" },
        }

        local function is_linter_enabled(linter_name, bufnr)
            local markers = root_markers_by_linter[linter_name]
            if not markers then
                return true
            end
            local path = vim.api.nvim_buf_get_name(bufnr)
            return vim.fs.find(markers, { upward = true, path = vim.fs.dirname(path) })[1] ~= nil
        end

        vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
            callback = function(args)
                lint.try_lint(nil, {
                    filter = function(linter)
                        return is_linter_enabled(linter.name, args.buf)
                    end,
                })
                lint.try_lint "cspell"
            end,
        })
    end,
}
