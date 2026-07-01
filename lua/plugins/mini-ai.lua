return {
    name = "mini.ai",
    repo = "nvim-mini/mini.ai",
    depends = { "mini.extra" },
    on_event = { "VimEnter" },
    lua_source = function()
        local gen_ai_spec = require("mini.extra").gen_ai_spec
        require("mini.ai").setup {
            custom_textobjects = {
                B = gen_ai_spec.buffer(),
                D = gen_ai_spec.diagnostic(),
                I = gen_ai_spec.indent(),
                L = gen_ai_spec.line(),
                N = gen_ai_spec.number(),
            },
            mappings = {
                -- To prioritize v_an / v_in in 0.12, the mini.ai side has been disabled
                around_next = "",
                inside_next = "",
                around_last = "",
                inside_last = "",
            },
        }
    end,
}
