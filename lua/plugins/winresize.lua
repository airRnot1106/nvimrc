return {
    name = "winresize",
    repo = "pogyomo/winresize.nvim",
    depends = { "submode" },
    on_map = { n = { "<C-w><C-w>" } },
    lua_source = function()
        local submode = require "submode"
        local resize = require("winresize").resize
        submode.create("WinResize", {
            mode = "n",
            enter = "<C-w><C-w>",
            leave = { "q", "<ESC>" },
            default = function(register)
                register("h", function()
                    resize(0, 2, "left")
                end)
                register("j", function()
                    resize(0, 1, "down")
                end)
                register("k", function()
                    resize(0, 1, "up")
                end)
                register("l", function()
                    resize(0, 2, "right")
                end)
            end,
        })
    end,
}
