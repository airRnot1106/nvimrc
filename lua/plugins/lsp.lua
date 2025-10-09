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

            ---@type vim.lsp.Config
            vim.lsp.config("*", {
                capabilities = require("ddc_source_lsp").make_client_capabilities(),
            })

            local lsp_names = {
                "astro",
                "biome",
                "denols",
                "gleam",
                "jsonls",
                "lua_ls",
                "mdx_analyzer",
                "nil_ls",
                "rust_analyzer",
                "ts_ls",
                "tsp_server",
                "vue_ls",
            }

            vim.lsp.enable(lsp_names)

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
    -- {
    --     "mfussenegger/nvim-lint",
    --     event = { "BufReadPre", "BufNewFile" },
    --     config = function()
    --         local lint = require "lint"
    --
    --         -- 各linterの設定
    --         lint.linters.cspell.args = vim.list_extend(lint.linters.cspell.args, {
    --             "--config",
    --             vim.fn.expand "~/.config/cspell/cspell.json",
    --         })
    --         lint.linters.luacheck.args = vim.list_extend(lint.linters.luacheck.args, {
    --             "--globals",
    --             "vim",
    --             "Snacks",
    --         })
    --
    --         -- javascript系で使用するlinterのリスト
    --         local js_linters = { "eslint", "markuplint" }
    --
    --         -- filetypeごとのlinterの設定
    --         lint.linters_by_ft = {
    --             javascript = js_linters,
    --             javascriptreact = js_linters,
    --             lua = { "luacheck" },
    --             python = { "ruff" },
    --             typescript = js_linters,
    --             typescriptreact = js_linters,
    --         }
    --
    --         -- javascript系のlinterの存在判定に使用するファイルの一覧
    --         local linter_root_markers = {
    --             eslint = {
    --                 "eslint.config.js",
    --                 "eslint.config.mjs",
    --                 "eslint.config.cjs",
    --                 "eslint.config.ts",
    --                 "eslint.config.mts",
    --                 "eslint.config.cts",
    --                 -- deprecated
    --                 ".eslintrc.js",
    --                 ".eslintrc.cjs",
    --                 ".eslintrc.yaml",
    --                 ".eslintrc.yml",
    --                 ".eslintrc.json",
    --             },
    --             markuplint = {
    --                 ".markuplintrc",
    --                 ".markuplintrc.json",
    --                 ".markuplintrc.yaml",
    --                 ".markuplintrc.yml",
    --             },
    --         }
    --
    --         -- javascript系のfiletypeの一覧
    --         local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
    --
    --         -- linter実行時の処理
    --         local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    --         vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    --             group = lint_augroup,
    --             callback = function(args)
    --                 local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
    --
    --                 -- filetypeの判定
    --                 if vim.tbl_contains(js_filetypes, filetype) then
    --                     -- javascript系のlinterを実行
    --                     -- Denoプロジェクトの場合はDenoのlinterを優先して実行
    --                     if require("lspconfig.util").root_pattern("deno.json", "deno.jsonc", "deps.ts")(args.buf) then
    --                         lint.try_lint "deno"
    --                     else
    --                         -- linterの一覧を取得
    --                         local names = lint.linters_by_ft[filetype] or {}
    --
    --                         -- linterが登録されているか、存在しているかを判定
    --                         for _, name in pairs(names) do
    --                             local next = next
    --                             if
    --                                 linter_root_markers[name] == nil
    --                                 or next(vim.fs.find(linter_root_markers[name], { upward = true }))
    --                             then
    --                                 lint.try_lint(name)
    --                             end
    --                         end
    --                     end
    --                 else
    --                     -- javascript系以外のfiletypeのlinterを実行
    --                     lint.try_lint()
    --                 end
    --
    --                 -- filetypeに依存しないlinterを実行
    --                 lint.try_lint "cspell"
    --             end,
    --         })
    --     end,
    -- },
}
