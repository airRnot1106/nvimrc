return {
    name = "lspconfig",
    repo = "neovim/nvim-lspconfig",
    depends = { "ddc-source-lsp" },
    on_event = { "VimEnter" },
    lua_source = function()
        local lsp_names = {
            "denols",
            "lua_ls",
        }
        vim.lsp.enable(lsp_names)

        vim.lsp.config("*", {
            capabilities = require("ddc_source_lsp").make_client_capabilities(),
        })

        vim.diagnostic.config {
            float = {
                border = "rounded",
                source = true,
            },
            severity_sort = false,
            signs = true,
            underline = true,
            update_in_insert = false,
            virtual_text = false,
        }

        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function()
                vim.keymap.set("n", "<C-k>", "<Cmd>lua vim.lsp.buf.hover()<CR>", { desc = "LSP hover" })
                vim.keymap.set("n", "<F2>", "<Cmd>lua vim.lsp.buf.rename()<CR>", { desc = "LSP rename" })
                vim.keymap.set("n", "<Leader>.", "<Cmd>lua vim.lsp.buf.code_action()<CR>", { desc = "LSP code action" })
                vim.keymap.set("n", "grd", "<Cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition" })
                vim.keymap.set("n", "grD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", { desc = "Go to declaration" })
                vim.keymap.set("n", "ge", "<Cmd>lua vim.diagnostic.open_float()<CR>", { desc = "Show diagnostic" })
                vim.keymap.set(
                    "n",
                    "grf",
                    "<Cmd>lua vim.lsp.buf.format({ async = false })<CR>",
                    { desc = "LSP format" }
                )
            end,
        })
    end,
}
