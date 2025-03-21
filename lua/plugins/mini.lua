return {
    {
        "echasnovski/mini.comment",
        version = false,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("mini.comment").setup {
                mappings = {
                    comment = "<Leader>/",
                    comment_line = "<Leader>/",
                    comment_visual = "<Leader>/",
                    textobject = "<Leader>/",
                },
            }
        end,
    },
    {
        "echasnovski/mini.indentscope",
        version = false,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("mini.indentscope").setup()
        end,
    },
    {
        "echasnovski/mini.files",
        version = false,
        config = function()
            local function split(str, ts)
                if ts == nil then
                    return {}
                end

                local t = {}
                local i = 1
                for s in string.gmatch(str, "([^" .. ts .. "]+)") do
                    t[i] = s
                    i = i + 1
                end

                return t
            end
            local function table_contains(table, element)
                for _, value in pairs(table) do
                    if value == element then
                        return true
                    end
                end
                return false
            end
            require("mini.files").setup {
                content = {
                    filter = function(file)
                        local ignored_files = {
                            ".DS_Store",
                        }

                        local t = split(file.path, "/")
                        local file_name = t[#t]

                        return not table_contains(ignored_files, file_name)
                    end,
                },
                mappings = {
                    go_in_plus = "<CR>",
                },
                windows = {
                    preview = true,
                },
            }
        end,
    },
    {
        "echasnovski/mini.cursorword",
        version = false,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("mini.cursorword").setup()
        end,
    },
    {
        "echasnovski/mini.splitjoin",
        version = false,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("mini.splitjoin").setup()
        end,
    },
    {
        "echasnovski/mini.trailspace",
        version = false,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("mini.trailspace").setup()
        end,
    },
    {
        "echasnovski/mini.extra",
        version = false,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("mini.extra").setup()
        end,
    },
    {
        "echasnovski/mini.ai",
        version = false,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local gen_ai_spec = require("mini.extra").gen_ai_spec
            require("mini.ai").setup {
                custom_textobjects = {
                    B = gen_ai_spec.buffer(),
                    D = gen_ai_spec.diagnostic(),
                    I = gen_ai_spec.indent(),
                    L = gen_ai_spec.line(),
                    N = gen_ai_spec.number(),
                },
            }
        end,
    },
    {
        "echasnovski/mini.hipatterns",
        version = false,
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local hipatterns = require "mini.hipatterns"
            local hi_words = require("mini.extra").gen_highlighter.words
            hipatterns.setup {
                highlighters = {
                    -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
                    fixme = hi_words({ "FIXME", "Fixme", "fixme" }, "MiniHipatternsFixme"),
                    hack = hi_words({ "HACK", "Hack", "hack" }, "MiniHipatternsHack"),
                    todo = hi_words({ "TODO", "Todo", "todo" }, "MiniHipatternsTodo"),
                    note = hi_words({ "NOTE", "Note", "note" }, "MiniHipatternsNote"),
                    -- Highlight hex color strings (`#rrggbb`) using that color
                    hex_color = hipatterns.gen_highlighter.hex_color(),
                },
            }
        end,
    },
}
