return {
    name = "nvim-mado-scratch",
    repo = "airRnot1106/nvim-mado-scratch",
    rev = "feature/edit-open-method",
    on_cmd = {
        "MadoScratchOpen",
        "MadoScratchClean",
        "MadoScratchOpenFile",
        "MadoScratchOpenNext",
        "MadoScratchOpenFileNext",
    },
    lua_source = function()
        require("mado-scratch").setup {
            -- Optional configuration (these are defaults)
            file_pattern = {
                when_tmp_buffer = "/tmp/mado-scratch-tmp-%d",
                when_file_buffer = "/tmp/mado-scratch-file-%d",
            },
            default_file_ext = "md",
            default_open_method = { method = "edit" },
            auto_save_file_buffer = true,
            use_default_keymappings = true, -- Set to true to enable default keymaps
            auto_hide_buffer = {
                when_tmp_buffer = false,
                when_file_buffer = false,
            },
        }
    end,
}
