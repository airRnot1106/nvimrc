return {
    name = "conform",
    repo = "stevearc/conform.nvim",
    on_event = { "BufReadPre", "BufNewFile" },
    lua_source = function()
        local util = require "conform.util"

        local function pick(groups)
            return function(bufnr)
                local conform = require "conform"
                local result = {}
                for _, group in ipairs(groups) do
                    if type(group) == "string" then
                        table.insert(result, group)
                    else
                        for _, name in ipairs(group) do
                            if conform.get_formatter_info(name, bufnr).available then
                                table.insert(result, name)
                                break
                            end
                        end
                    end
                end
                return result
            end
        end

        local js =
            pick { { "biome-organize-imports" }, { "oxlint" }, { "deno_fmt", "oxfmt", "biome-check", "prettierd" } }
        local md = pick { { "oxfmt", "prettierd" } }

        require("conform").setup {
            formatters = {
                ["biome-check"] = { require_cwd = true },
                ["biome-organize-imports"] = { require_cwd = true },
                deno_fmt = {
                    cwd = util.root_file { "deno.json", "deno.jsonc" },
                    require_cwd = true,
                },
                oxfmt = { require_cwd = true },
                oxlint = { require_cwd = true },
                prettierd = { require_cwd = true },
            },
            formatters_by_ft = {
                astro = js,
                bash = { "shfmt" },
                gleam = { "gleamfmt" },
                javascript = js,
                javascriptreact = js,
                json = js,
                jsonc = js,
                kdl = { "kdlfmt" },
                lua = { "stylua" },
                markdown = md,
                nix = { "nixfmt" },
                python = pick { { "ruff_organize_imports" }, { "ruff_fix" }, { "ruff_format", "black" } },
                rust = { "rustfmt" },
                sh = { "shfmt" },
                typescript = js,
                typescriptreact = js,
            },
            format_on_save = {
                timeout_ms = 1000,
                lsp_format = "fallback",
            },
        }
    end,
}
