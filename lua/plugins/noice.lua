return {
    {
        "folke/noice.nvim",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
        event = { "VeryLazy" },
        config = function()
            local special_chars = {
                ["("] = "%(",
                [")"] = "%)",
                ["."] = "%.",
                ["%"] = "%%",
                ["+"] = "%+",
                ["-"] = "%-",
                ["*"] = "%*",
                ["?"] = "%?",
                ["["] = "%[",
                ["]"] = "%]",
                ["^"] = "%^",
                ["$"] = "%$",
            }

            local function pattern_quote(s)
                return string.gsub(s, ".", special_chars)
            end

            require("noice").setup {
                views = {
                    cmdline_popup = {
                        position = {
                            row = "50%",
                            col = "50%",
                        },
                    },
                },
                routes = {
                    {
                        filter = {
                            event = "msg_show",
                            kind = "",
                            find = "written",
                        },
                        opts = { skip = true },
                    },
                    {
                        filter = {
                            event = "notify",
                            kind = "info",
                            find = "^" .. pattern_quote "[LSP] Format request failed, no matching",
                        },
                        opts = { skip = true },
                    },
                },
                cmdline = {
                    enabled = true,
                    view = "cmdline",
                    format = {
                        cmdline = { pattern = "^:", icon = ":", lang = "vim" },
                    },
                },
                lsp = {
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                    },
                },
                presets = {
                    bottom_search = true,
                    command_palette = true,
                    long_message_to_split = true,
                    inc_rename = false,
                    lsp_doc_border = true,
                },
            }
            require("notify").setup {
                timeout = 2000,
                stages = "static",
            }
        end,
    },
}
