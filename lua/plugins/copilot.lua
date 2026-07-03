return {
    name = "copilot",
    repo = "zbirenbaum/copilot.lua",
    depends = { "copilot-lsp" },
    on_cmd = { "Copilot" },
    on_event = { "InsertEnter" },
    lua_source = function()
        local accept_and_goto_key = "<C-y>"

        require("copilot").setup {
            suggestion = { enabled = false },
            panel = { enabled = false },
            nes = {
                enabled = true,
                keymap = {
                    accept_and_goto = accept_and_goto_key,
                    accept = false,
                    dismiss = "<Esc>",
                },
            },
        }

        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client or client.name ~= "copilot" then
                    return
                end

                require("copilot.keymaps").register_keymap_with_passthrough("i", accept_and_goto_key, function()
                    local nes_api = require "copilot.nes.api"
                    local applied = nes_api.nes_apply_pending_nes()
                    if applied then
                        nes_api.nes_walk_cursor_end_edit()
                    end
                    return applied
                end, "[copilot] (nes) accept suggestion and jump to suggestion tail (insert)", args.buf)
            end,
        })

        vim.api.nvim_create_autocmd("LspDetach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client or client.name ~= "copilot" then
                    return
                end

                require("copilot.keymaps").unset_keymap_if_exists("i", accept_and_goto_key, args.buf)
            end,
        })
    end,
}
