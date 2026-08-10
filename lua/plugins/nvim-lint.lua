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

        local function resolve_cmd(cmd)
            if vim.is_callable(cmd) then
                local ok, resolved = pcall(cmd)
                return ok and resolved or nil
            end
            return cmd
        end

        local function is_linter_enabled(linter, bufnr)
            local markers = root_markers_by_linter[linter.name]
            if markers then
                local path = vim.api.nvim_buf_get_name(bufnr)
                if vim.fs.find(markers, { upward = true, path = vim.fs.dirname(path) })[1] == nil then
                    return false
                end
            end

            local cmd = resolve_cmd(linter.cmd)
            if type(cmd) ~= "string" or vim.fn.executable(cmd) ~= 1 then
                return false
            end

            return true
        end

        vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
            callback = function(args)
                lint.try_lint(nil, {
                    filter = function(linter)
                        return is_linter_enabled(linter, args.buf)
                    end,
                })
                lint.try_lint "cspell"
            end,
        })
    end,
}
