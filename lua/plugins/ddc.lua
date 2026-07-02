return {
    name = "ddc",
    repo = "Shougo/ddc.vim",
    depends = {
        "ddc-emoji",
        "ddc-fuzzy",
        "ddc-path",
        "ddc-source-around",
        "ddc-source-buffer",
        "ddc-source-cmdline",
        "ddc-source-cmdline_history",
        "ddc-source-copilot",
        "ddc-source-file",
        "ddc-source-lsp",
        "ddc-source-maccy",
        "ddc-source-mocword",
        "ddc-source-rg",
        "ddc-ui-pum",
        "nvim-autopairs",
        "pum",
        "skkeleton",
    },
    on_event = { "CmdlineChanged", "CmdlineEnter", "InsertEnter", "TextChangedI", "TextChangedP" },
    lua_source = function()
        local patch_global = vim.fn["ddc#custom#patch_global"]

        patch_global("ui", "pum")
        vim.fn["pum#set_option"] {
            padding = true,
        }

        patch_global("autoCompleteEvents", {
            "CmdlineChanged",
            "CmdlineEnter",
            "InsertEnter",
            "TextChangedI",
            "TextChangedP",
        })

        patch_global("sources", {
            "maccy",
            "copilot",
            "skkeleton",
            "skkeleton_okuri",
            "lsp",
            "around",
            "buffer",
            "rg",
            "mocword",
            "file",
            "path",
            "emoji",
        })
        patch_global("cmdlineSources", {
            [":"] = {
                "skkeleton",
                "skkeleton_okuri",
                "cmdline",
                "cmdline_history",
                "rg",
                "file",
                "path",
            },
        })

        patch_global("sourceOptions", {
            ["_"] = {
                matchers = { "matcher_fuzzy" },
                sorters = { "sorter_fuzzy" },
                converters = { "converter_fuzzy" },
            },
            around = {
                mark = "[A]",
            },
            buffer = {
                mark = "[B]",
            },
            cmdline = {
                mark = "[C]",
                minAutoCompleteLength = 1,
            },
            cmdline_history = {
                mark = "history",
                sorters = { "sorter_cmdline_history" },
                minAutoCompleteLength = 1,
            },
            copilot = {
                mark = "[Copilot]",
                matchers = {},
                minAutoCompleteLength = 0,
                isVolatile = true,
            },
            emoji = {
                mark = "[E]",
                matchers = { "emoji" },
                sorters = {},
                keywordPattern = [[[a-zA-Z_:]\w*]],
            },
            file = {
                mark = "[F]",
                maxItems = 3,
                isVolatile = true,
                keywordPattern = [[[a-zA-Z0-9_.~-]*/[a-zA-Z0-9_.~/-]*]],
                forceCompletionPattern = "\\S/\\S*",
                minAutoCompleteLength = 1,
            },
            lsp = {
                mark = "[LSP]",
                isVolatile = true,
                forceCompletionPattern = [[\.\w*|:\w*|->\w*]],
            },
            maccy = {
                mark = "[Maccy]",
                maxItems = 3,
                matchers = {},
                sorters = {},
                converters = {},
                isVolatile = true,
                minAutoCompleteLength = 0,
            },
            mocword = {
                mark = "[M]",
                maxItems = 8,
                isVolatile = true,
                keywordPattern = [[[a-zA-Z]+(?: +[a-zA-Z]*)*]],
                minAutoCompleteLength = 3,
            },
            path = {
                mark = "[P]",
                maxItems = 3,
                keywordPattern = [[[a-zA-Z0-9_.~-]*/[a-zA-Z0-9_.~/-]*]],
                forceCompletionPattern = "\\S/\\S*",
                minAutoCompleteLength = 1,
            },
            rg = {
                mark = "[R]",
                minAutoCompleteLength = 4,
            },
            skkeleton = {
                mark = "[SKK]",
                matchers = {},
                sorters = {},
                converters = {},
                isVolatile = true,
                minAutoCompleteLength = 1,
            },
            skkeleton_okuri = {
                mark = "[SKK*]",
                matchers = {},
                sorters = {},
                converters = {},
                isVolatile = true,
            },
        })

        patch_global("sourceParams", {
            around = {
                maxSize = 500,
            },
            buffer = {
                requireSameFiletype = false,
                limitBytes = 5000000,
                fromAltBuf = true,
                forceCollect = true,
            },
            copilot = {
                copilot = "lua",
            },
            lsp = {
                snippetEngine = vim.fn["denops#callback#register"](function(body)
                    vim.snippet.expand(body)
                end),
                enableResolveItem = true,
                enableAdditionalTextEdit = true,
            },
            maccy = {
                recentMs = 30000,
                cacheTtlMs = 2000,
                types = { "public.utf8-plain-text" },
                dbPath = "~/Library/Containers/org.p0deje.Maccy/Data/Library/Application Support/Maccy/Storage.sqlite",
                maxByteLength = 10000,
            },
            path = {
                absolute = false,
                cmd = { "fd", "--max-depth", "5" },
            },
        })

        vim.fn["ddc#enable"]()

        local function pum_or(rhs, fallback)
            return function()
                return vim.fn["pum#visible"]() and rhs or fallback
            end
        end

        vim.keymap.set(
            "i",
            "<C-n>",
            pum_or("<Cmd>call pum#map#insert_relative(+1)<CR>", "<C-n>"),
            { expr = true, desc = "Completion next" }
        )
        vim.keymap.set(
            "i",
            "<C-p>",
            pum_or("<Cmd>call pum#map#insert_relative(-1)<CR>", "<C-p>"),
            { expr = true, desc = "Completion previous" }
        )
        vim.keymap.set("i", "<CR>", function()
            if vim.fn["pum#visible"]() and vim.fn["pum#entered"]() then
                return vim.api.nvim_replace_termcodes("<Cmd>call pum#map#confirm()<CR>", true, true, true)
            end
            return require("nvim-autopairs").autopairs_cr()
        end, { expr = true, replace_keycodes = false, desc = "Completion confirm / autopairs CR" })
        vim.keymap.set(
            "i",
            "<C-e>",
            pum_or("<Cmd>call pum#map#cancel()<CR>", "<C-e>"),
            { expr = true, desc = "Completion cancel" }
        )

        local function commandline_pre()
            local maps = {
                ["<C-n>"] = "+1",
                ["<C-p>"] = "-1",
            }
            for lhs, delta in pairs(maps) do
                vim.keymap.set(
                    "c",
                    lhs,
                    "<Cmd>call pum#map#insert_relative(" .. delta .. ")<CR>",
                    { desc = "Cmdline completion" }
                )
            end
            vim.keymap.set("c", "<C-y>", "<Cmd>call pum#map#confirm()<CR>", { desc = "Cmdline confirm" })
            vim.keymap.set("c", "<C-e>", "<Cmd>call pum#map#cancel()<CR>", { desc = "Cmdline cancel" })

            vim.api.nvim_create_autocmd("User", {
                pattern = "DDCCmdlineLeave",
                once = true,
                callback = function()
                    for lhs in pairs(maps) do
                        pcall(vim.keymap.del, "c", lhs)
                    end
                    pcall(vim.keymap.del, "c", "<C-y>")
                    pcall(vim.keymap.del, "c", "<C-e>")
                end,
            })

            vim.fn["ddc#enable_cmdline_completion"]()
        end

        vim.keymap.set("n", ":", function()
            commandline_pre()
            return ":"
        end, { expr = true, desc = "Cmdline completion" })
    end,
}
