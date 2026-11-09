return {
    name = "goda-cmp",
    "Shougo/goda-cmp.vim",
    dependencies = { "goda.vim", "pum" },
    lazy = true,
    build = ":call goda_cmp#build()",
}
