return {
    name = "vimdoc-ja",
    "vim-jp/vimdoc-ja",
    -- lazy.nvim regenerates the helptags, and this repo tracks doc/tags-ja
    build = "git checkout -- doc/tags-ja",
}
