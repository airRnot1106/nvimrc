return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = { "InsertEnter" },
        config = function()
            require("copilot").setup {
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    hide_during_completion = true,
                    debounce = 75,
                    keymap = {
                        accept = "<C-h>",
                        dismiss = "<Esc>",
                    },
                },
                copilot_node_command = "node",
            }
        end,
    },
}
