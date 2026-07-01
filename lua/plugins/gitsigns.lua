return {
    name = "gitsigns",
    repo = "lewis6991/gitsigns.nvim",
    on_event = { "VimEnter" },
    lua_source = function()
        local gitsigns = require "gitsigns"
        gitsigns.setup {
            current_line_blame = true,
            on_attach = function(bufnr)
                local function map(mode, lhs, rhs, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, lhs, rhs, opts)
                end

                -- navigation (fall back to native diff jumps in diff mode)
                map("n", "]h", function()
                    if vim.wo.diff then
                        vim.cmd "normal! ]c"
                    else
                        gitsigns.nav_hunk "next"
                    end
                end, { desc = "Next hunk" })
                map("n", "[h", function()
                    if vim.wo.diff then
                        vim.cmd "normal! [c"
                    else
                        gitsigns.nav_hunk "prev"
                    end
                end, { desc = "Previous hunk" })

                -- blame & diff
                map("n", "<Leader>gb", function()
                    gitsigns.blame_line { full = true }
                end, { desc = "Blame line" })
                map("n", "<Leader>gB", gitsigns.toggle_current_line_blame, { desc = "Toggle line blame" })
            end,
        }
    end,
}
