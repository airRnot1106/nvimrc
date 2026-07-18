return {
    name = "terminals",
    repo = "sassanh/terminals.nvim",
    lazy = false,
    lua_source = function()
        local keys = {
            go_left = "<C-w>h",
            go_right = "<C-w>l",
            move_left = "<C-w>H",
            move_right = "<C-w>L",
            toggle = "<F7>",
            cycle_layout = "<D-m>",
            toggle_reverse_search = "<C-/>",
            focus = "<D-i>",
            unfocus = "<D-S-i>",
            leave = "<D-[>",
            paste = "<C-p>",
            paste_in_place = "<C-S-p>",
            modifier = "D",
        }

        require("terminals").setup {
            keys = keys,
            preserved_keys = {},
        }

        pcall(vim.keymap.del, "n", keys.go_left)
        pcall(vim.keymap.del, "n", keys.go_right)
        pcall(vim.keymap.del, "n", keys.move_left)
        pcall(vim.keymap.del, "n", keys.move_right)
        pcall(vim.keymap.del, "n", keys.cycle_layout)
        pcall(vim.keymap.del, "n", keys.toggle_reverse_search)
        pcall(vim.keymap.del, "i", keys.toggle_reverse_search)
        for i = 0, 9 do
            pcall(vim.keymap.del, "n", ("<%s-%s>"):format(keys.modifier, i))
        end

        vim.api.nvim_create_autocmd("BufFilePost", {
            pattern = "term://Terminal-*",
            callback = function(args)
                -- keep Terminal-n buffers out of bufferline/tab plugins (e.g. barbar)
                vim.bo[args.buf].buflisted = false

                local logic = require "terminals.logic"
                local opts = { buffer = args.buf, silent = true }

                vim.keymap.set("n", keys.go_left, function()
                    logic.save_terminal_state(false)
                    logic.navigate(-1)
                end, opts)
                vim.keymap.set("n", keys.go_right, function()
                    logic.save_terminal_state(false)
                    logic.navigate(1)
                end, opts)
                vim.keymap.set("n", keys.move_left, function()
                    logic.move_terminal(-1)
                end, opts)
                vim.keymap.set("n", keys.move_right, function()
                    logic.move_terminal(1)
                end, opts)
                vim.keymap.set("n", keys.cycle_layout, function()
                    logic.cycle_layout()
                end, opts)
                vim.keymap.set("n", keys.toggle_reverse_search, "?", opts)
                for i = 0, 9 do
                    vim.keymap.set("n", ("<%s-%s>"):format(keys.modifier, i), function()
                        logic.save_terminal_state(false)
                        logic.activate_terminal { id = i }
                    end, opts)
                end
            end,
        })
    end,
}
