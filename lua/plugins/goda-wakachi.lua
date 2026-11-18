local motions = { "w", "b", "e", "ge" }
local smartword_motions = { w = true, b = true, e = true }

return {
    name = "goda-wakachi",
    "airRnot1106/goda-wakachi.vim",
    dependencies = { "goda.vim", "vim-smartword" },
    build = "nix build",
    keys = vim.tbl_map(function(motion)
        return { motion, mode = { "n", "x", "o" } }
    end, motions),
    config = function()
        for _, motion in ipairs(motions) do
            local wakachi = "<Plug>(goda-wakachi-" .. motion .. ")"
            vim.keymap.set({ "x", "o" }, motion, wakachi, { remap = true, silent = true })

            if smartword_motions[motion] then
                -- goda-wakachi falls back to the native motion on an ASCII line, so smartword takes those lines.
                vim.keymap.set("n", motion, function()
                    local is_ascii = vim.api.nvim_get_current_line():match "^[\1-\127]+$"
                    return is_ascii and "<Plug>(smartword-" .. motion .. ")" or wakachi
                end, { expr = true, remap = true, silent = true })
            else
                vim.keymap.set("n", motion, wakachi, { remap = true, silent = true })
            end
        end
    end,
}
