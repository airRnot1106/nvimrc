local function builtin(name)
    return function()
        require("telescope.builtin")[name]()
    end
end

local function extension(ext, name)
    return function()
        require("telescope").extensions[ext][name]()
    end
end

return {
    name = "telescope",
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-notify",
        "nvim-web-devicons",
        "plenary",
        "smart-open",
        "sqlite",
        "telescope-fzf-native",
        "telescope-maccy",
    },
    keys = {
        { "<Leader>fb", builtin "buffers", desc = "Telescope buffers" },
        { "<Leader>fc", builtin "command_history", desc = "Telescope command history" },
        { "<Leader>fd", builtin "diagnostics", desc = "Telescope diagnostics" },
        { "<Leader>ff", extension("smart_open", "smart_open"), desc = "Telescope smart open" },
        { "<Leader>fg", builtin "live_grep", desc = "Telescope live grep" },
        { "<Leader>fh", builtin "help_tags", desc = "Telescope help tags" },
        { "<Leader>fk", builtin "keymaps", desc = "Telescope keymaps" },
        { "<Leader>fld", builtin "lsp_definitions", desc = "Telescope LSP definitions" },
        { "<Leader>fli", builtin "lsp_implementations", desc = "Telescope LSP implementations" },
        { "<Leader>flr", builtin "lsp_references", desc = "Telescope LSP references" },
        { "<Leader>flt", builtin "lsp_type_definitions", desc = "Telescope LSP type definitions" },
        { "<Leader>fm", extension("maccy", "maccy"), desc = "Telescope maccy" },
        { "<Leader>fn", extension("notify", "notify"), desc = "Telescope notify" },
        { "<Leader>fp", builtin "pickers", desc = "Telescope pickers" },
        { "<Leader>fr", builtin "resume", desc = "Telescope resume" },
    },
    init = function()
        vim.g.sqlite_clib_path = "/usr/lib/libsqlite3.dylib"
    end,
    config = function()
        -- setup telescope
        require("telescope").setup {
            defaults = {
                vimgrep_arguments = {
                    "rg",
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                    "--hidden",
                    "--glob=!**/.DS_Store",
                    "--glob=!**/.direnv/*",
                    "--glob=!**/.next/*",
                    "--glob=!**/.git/*",
                    "--glob=!**/dist/*",
                    "--glob=!**/node_modules/*",
                    "--glob=!**/package-lock.json",
                },
                mappings = {
                    n = {
                        q = require("telescope.actions").close,
                    },
                },
            },
        }

        -- load extensions
        local load_extension = require("telescope").load_extension

        load_extension "fzf"
        load_extension "maccy"
        load_extension "notify"
        load_extension "smart_open"
    end,
}
