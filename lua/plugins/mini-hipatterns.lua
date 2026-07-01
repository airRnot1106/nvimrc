return {
    name = "mini.hipatterns",
    repo = "nvim-mini/mini.hipatterns",
    depends = { "mini.extra" },
    on_event = { "BufReadPre", "BufNewFile" },
    lua_source = function()
        local hipatterns = require "mini.hipatterns"
        local hi_words = require("mini.extra").gen_highlighter.words
        hipatterns.setup {
            highlighters = {
                fixme = hi_words({ "FIXME", "Fixme", "fixme" }, "MiniHipatternsFixme"),
                todo = hi_words({ "TODO", "Todo", "todo" }, "MiniHipatternsTodo"),
                hex_color = hipatterns.gen_highlighter.hex_color(),
            },
        }
    end,
}
