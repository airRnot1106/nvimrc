return {
    name = "copilot",
    repo = "zbirenbaum/copilot.lua",
    depends = { "copilot-lsp" },
    on_cmd = { "Copilot" },
    on_event = { "InsertEnter" },
    lua_source = function()
        require("copilot").setup {
            suggestion = { enabled = false },
            panel = { enabled = false },
            nes = {
                enabled = true,
                keymap = {
                    accept_and_goto = "<C-y>",
                    accept = false,
                    dismiss = "<Esc>",
                },
            },
        }
    end,
}
